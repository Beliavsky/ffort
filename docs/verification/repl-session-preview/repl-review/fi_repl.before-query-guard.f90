! SPDX-License-Identifier: MIT
! Bounded source-body REPL with validated scalar sessions. Explicit .run resets;
! queries execute only pending instructions and an ephemeral print, never replay.
! No implicit saves, fabricated variable inspection or host file access.
module fi_repl
    use, intrinsic :: iso_fortran_env, only: int64, input_unit, output_unit, error_unit, iostat_end, iostat_eor
    use fi_limits, only: max_source_bytes
    use fi_ir, only: program_t, diagnostic_t
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program, scalar_session_t, reset_scalar_session, &
        execute_scalar_session, validate_scalar_session_program, validate_scalar_session_query
    implicit none
    private
    public :: run_repl
    integer, parameter :: line_limit=4096, line_count_limit=10000
    character(*), parameter :: header='program repl_session'//achar(10)//'implicit none'//achar(10)
    character(*), parameter :: footer='end program repl_session'//achar(10)
contains
    subroutine run_repl(status,max_steps,show_prompt,show_banner,prompt_text)
        integer, intent(out) :: status
        integer(int64), intent(in), optional :: max_steps
        logical, intent(in), optional :: show_prompt,show_banner
        character(*), intent(in), optional :: prompt_text
        character(:), allocatable :: body,next,source,command,prompt
        character(line_limit+1) :: line
        integer :: ios,n,nlines,alloc_status,j
        integer(int64) :: steps
        logical :: prompts,banner,ended,too_long,layout_frozen,nonresumable
        type(scalar_session_t) :: session
        status=0; steps=1000000_int64; prompts=.true.; banner=.true.
        if(present(max_steps)) steps=max_steps
        if(present(show_prompt)) prompts=show_prompt
        if(present(show_banner)) banner=show_banner
        prompt='> '
        if(present(prompt_text)) prompt=prompt_text
        if(steps<=0) then
            call repl_error('max_steps must be positive',status); return
        end if
        if(len(prompt)>128) then
            call repl_error('prompt exceeds 128 bytes',status); return
        end if
        do j=1,len(prompt)
            if(iachar(prompt(j:j))<32.or.iachar(prompt(j:j))==127) then
                call repl_error('prompt contains a control character',status); return
            end if
        end do
        body=''; nlines=0; layout_frozen=.false.; nonresumable=.false.
        call reset_scalar_session(session)
        if(banner) then
            write(output_unit,'(a)',iostat=ios) 'FortFront source-buffer REPL. Enter Fortran body lines; .help for commands.'
            if(ios/=0) then
                status=2; return
            end if
        end if
        do
            if(prompts) then
                write(output_unit,'(a)',advance='no',iostat=ios) prompt
                if(ios/=0) then
                    status=2; return
                end if
                flush(output_unit,iostat=ios)
                if(ios/=0) then
                    status=2; return
                end if
            end if
            call read_repl_line(line,n,ended,too_long,ios)
            if(ios/=0) then
                call repl_error('input error',status); status=2; return
            end if
            if(ended.and.n==0.and..not.too_long) return
            if(too_long) then
                call repl_error('line exceeds 4096 bytes; discarded',status)
                if(ended) return
                cycle
            end if
            if(index(line(:n),achar(0))/=0) then
                call repl_error('NUL byte is not allowed; line discarded',status)
                if(ended) return
                cycle
            end if
            command=trim(adjustl(line(:n)))
            select case(command)
            case('.quit','.quit!')
                return
            case('.clear')
                body=''; nlines=0; status=0; layout_frozen=.false.; nonresumable=.false.
                call reset_scalar_session(session)
            case('.help')
                write(output_unit,'(a)',iostat=ios) &
                    '. or .run: compile and run the entire buffer with fresh state', &
                    '.list: show the standard Fortran wrapper and buffered body; .help: show this help', &
                    '.clear: clear the body and last error; .quit or .quit!: exit without saving', &
                    'Statements buffer; a bare scalar expression runs pending statements once and prints its value.', &
                    'Queries: scalar literals/names/arithmetic only, no calls. Declarations freeze after execution.', &
                    'Persistent state: straight-line nonallocatable intrinsic scalars only; runtime errors taint it.', &
                    'EOF does not run/save. .run resets state. Load/save and .vars remain unsupported.', &
                    'Limits: 4096 bytes per line, 10000 body lines, 1048576 total source bytes.'
                if(ios/=0) then
                    status=2; return
                end if
            case('.','.run','.list')
                allocate(character(len(header)+len(body)+len(footer))::source,stat=alloc_status)
                if(alloc_status/=0) then
                    call repl_error('cannot allocate source buffer',status); status=2; return
                end if
                source=header//body//footer
                if(command=='.list') then
                    write(output_unit,'(a)',advance='no',iostat=ios) source
                    if(ios/=0) then
                        status=2; return
                    end if
                else
                    call run_buffer(source,steps,session,layout_frozen,nonresumable,status)
                end if
                deallocate(source)
            case default
                if(is_expression_line(command).and..not.continued_body(body)) then
                    if(nonresumable) then
                        call repl_error('buffer ran outside scalar session subset; use .clear before querying',status)
                    else
                        call query_buffer(body,command,steps,session,layout_frozen,status)
                    end if
                    if(ended) return
                    cycle
                end if
                if(layout_frozen.and.is_declaration_line(command)) then
                    call repl_error('declarations are frozen; use .clear before changing them',status)
                    if(ended) return
                    cycle
                end if
                if(len(command)>0) then
                    if(command(1:1)=='.') then
                        call repl_error('unsupported command: '//command,status)
                        if(ended) return
                        cycle
                    end if
                end if
                if(nlines>=line_count_limit.or.len(body)+n+1+len(header)+len(footer)>max_source_bytes) then
                    call repl_error('source buffer limit exceeded; line discarded',status)
                else
                    allocate(character(len(body)+n+1)::next,stat=alloc_status)
                    if(alloc_status/=0) then
                        call repl_error('cannot grow source buffer',status); status=2; return
                    end if
                    next=body//line(:n)//achar(10)
                    call move_alloc(next,body); nlines=nlines+1
                end if
            end select
            if(ended) return
        end do
    end subroutine

    subroutine read_repl_line(line,n,ended,too_long,status)
        character(*),intent(out)::line
        integer,intent(out)::n,status
        logical,intent(out)::ended,too_long
        character(line_limit+1)::discard
        integer::ios,received
        n=0; status=0; ended=.false.; too_long=.false.
        read(input_unit,'(a)',advance='no',size=n,iostat=ios) line
        too_long=n>line_limit
        if(ios==0) then
            ! A full overlong chunk: drain its record so its tail cannot become a command.
            too_long=.true.
            do
                read(input_unit,'(a)',advance='no',size=received,iostat=ios) discard
                if(ios/=0) exit
            end do
        end if
        if(ios==iostat_end) then
            ended=.true.
        else if(ios/=iostat_eor) then
            status=1
        end if
    end subroutine

    subroutine repl_error(message,status)
        character(*),intent(in)::message
        integer,intent(out)::status
        integer::ios
        status=1
        write(error_unit,'(a)',iostat=ios) '<repl>: '//message
        if(ios/=0) status=2
    end subroutine

    subroutine compile_buffer(source,prog,diag)
        character(*),intent(in)::source
        type(program_t),intent(out)::prog
        type(diagnostic_t),intent(out)::diag
        call parse_subset(source,prog,diag)
        if(diag%code==0) call verify_frontend(source,prog,diag)
    end subroutine

    subroutine report_diagnostic(diag,status)
        type(diagnostic_t),intent(in)::diag
        integer,intent(out)::status
        integer::ios
        status=diag%code; ios=0
        if(diag%code==3) then
            status=diag%stop_status
            write(error_unit,'(a)',iostat=ios) diag%message
        else if(diag%code/=0) then
            write(error_unit,'(a,i0,a,i0,a,a)',iostat=ios) '<repl>:',diag%line,':',diag%column,': ',diag%message
        end if
        if(ios/=0) status=2
    end subroutine

    subroutine run_buffer(source,steps,session,frozen,nonresumable,status)
        character(*),intent(in)::source
        integer(int64),intent(in)::steps
        type(scalar_session_t),intent(inout)::session
        logical,intent(inout)::frozen,nonresumable
        integer,intent(out)::status
        type(program_t)::prog
        type(diagnostic_t)::diag,admission
        call compile_buffer(source,prog,diag)
        if(diag%code/=0) then
            call report_diagnostic(diag,status); return
        end if
        ! Decide before executing: never retry an effectful failed execution.
        call validate_scalar_session_program(prog,admission)
        call reset_scalar_session(session)
        frozen=.false.; nonresumable=admission%code/=0
        if(nonresumable) then
            call execute_program(prog,diag,max_steps=steps,program_name='<repl>')
        else
            call execute_scalar_session(session,prog,diag,max_steps=steps)
            frozen=diag%code==0
        end if
        call report_diagnostic(diag,status)
    end subroutine

    subroutine query_buffer(body,expression,steps,session,frozen,status)
        character(*),intent(in)::body,expression
        integer(int64),intent(in)::steps
        type(scalar_session_t),intent(inout)::session
        logical,intent(inout)::frozen
        integer,intent(out)::status
        type(program_t)::base,query
        type(diagnostic_t)::diag
        character(:),allocatable::source,query_source
        integer::ios
        if(len(header)+len(body)+len(footer)+len(expression)+12>max_source_bytes) then
            call repl_error('query exceeds source byte limit',status); return
        end if
        allocate(character(len(header)+len(body)+len(footer))::source,stat=ios)
        if(ios/=0) then
            call repl_error('cannot allocate query source',status); status=2; return
        end if
        source=header//body//footer
        call compile_buffer(source,base,diag)
        if(diag%code==0) call validate_scalar_session_program(base,diag)
        if(diag%code/=0) then
            call report_diagnostic(diag,status); return
        end if
        allocate(character(len(header)+len(body)+len(expression)+12+len(footer))::query_source,stat=ios)
        if(ios/=0) then
            call repl_error('cannot allocate query source',status); status=2; return
        end if
        query_source=header//body//'print *, ('//expression//')'//achar(10)//footer
        call compile_buffer(query_source,query,diag)
        if(diag%code==0) call validate_scalar_session_query(query,base%nc,diag)
        ! Both forms have passed admission before any pending source has effects.
        if(diag%code==0) call execute_scalar_session(session,base,diag,max_steps=steps)
        if(diag%code==0) then
            frozen=.true.
            call execute_scalar_session(session,query,diag,max_steps=steps,commit=.false.)
        end if
        call report_diagnostic(diag,status)
    end subroutine

    function first_word(line) result(word)
        character(*),intent(in)::line
        character(:),allocatable::word
        integer::i,k
        word=''
        do i=1,len_trim(line)
            k=iachar(line(i:i))
            if(k>=65.and.k<=90) k=k+32
            if(.not.((k>=97.and.k<=122).or.(k>=48.and.k<=57).or.k==95)) exit
            word=word//achar(k)
        end do
    end function

    logical function is_declaration_line(line) result(declaration)
        character(*),intent(in)::line
        declaration=.true.
        select case(first_word(line))
        case('integer','real','double','character','logical','complex','type','class', &
             'implicit','parameter','dimension','save','allocatable','pointer','target', &
             'external','intrinsic','optional','intent','public','private','use','import')
        case default
            declaration=.false.
        end select
    end function

    logical function continued_body(body) result(continued)
        character(*),intent(in)::body
        integer::start,i,last
        character::quote,c
        continued=.false.; start=1
        do while(start<=len(body))
            quote=' '; last=0; i=start
            do while(i<=len(body))
                c=body(i:i)
                if(c==achar(10)) exit
                if(quote/=' ') then
                    if(c==quote) then
                        if(i<len(body)) then
                            if(body(i+1:i+1)==quote) then
                                last=i+1;i=i+2;cycle
                            end if
                        end if
                        quote=' '
                    end if
                else
                    if(c=='!') then
                        do while(i<=len(body))
                            if(body(i:i)==achar(10)) exit
                            i=i+1
                        end do
                        exit
                    end if
                    if(c=="'".or.c=='"') quote=c
                end if
                if(c/=' '.and.c/=achar(9)) last=i
                i=i+1
            end do
            if(last>0) continued=body(last:last)=='&'
            start=i+1
        end do
    end function

    logical function is_expression_line(line) result(expression)
        character(*),intent(in)::line
        character::quote,c,prior,following
        integer::i,k
        expression=.false.
        if(len_trim(line)==0) return
        if(line(1:1)=='!'.or.line(1:1)=='&') return
        ! A leading decimal statement label followed by a word is source, not a query.
        i=1
        do while(i<=len(line))
            if(index('0123456789',line(i:i))==0) exit
            i=i+1
        end do
        if(i>1.and.i<=len(line)) then
            if(line(i:i)==' '.or.line(i:i)==achar(9)) then
                do while(i<=len(line))
                    if(line(i:i)/=' '.and.line(i:i)/=achar(9)) exit
                    i=i+1
                end do
                if(i<=len(line)) then
                    k=iachar(line(i:i))
                    if((k>=65.and.k<=90).or.(k>=97.and.k<=122)) return
                end if
            end if
        end if
        if(is_declaration_line(line)) return
        select case(first_word(line))
        case('program','end','subroutine','function','module','contains','if','then','else', &
             'elseif','do','select','case','call','print','write','read','allocate','deallocate', &
             'return','stop','error','exit','cycle','where','elsewhere','forall','block','associate', &
             'backspace','inquire','open','close','rewind','flush','format','data','continue')
            return
        end select
        if(line(1:1)=='.') then
            if(len(line)<2) return
            ! Known dot commands stay commands; logical literals and decimal literals may be queries.
            if(index('0123456789',line(2:2))==0) then
                if(first_word(line(2:))/='true'.and.first_word(line(2:))/='false'.and. &
                   first_word(line(2:))/='not') return
            end if
        end if
        quote=' ';i=1
        do while(i<=len(line))
            c=line(i:i)
            if(quote/=' ') then
                if(c==quote) then
                    if(i<len(line)) then
                        if(line(i+1:i+1)==quote) then
                            i=i+2;cycle
                        end if
                    end if
                    quote=' '
                end if
            else
                if(c=='!') exit
                if(c=="'".or.c=='"') quote=c
                if(c=='=') then
                    prior=' ';following=' '
                    if(i>1) prior=line(i-1:i-1)
                    if(i<len(line)) following=line(i+1:i+1)
                    if(index('=<>/',prior)==0.and.following/='=') return
                end if
                if(c==':') return
            end if
            i=i+1
        end do
        expression=.true.
    end function
end module
