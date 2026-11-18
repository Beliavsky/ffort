! SPDX-License-Identifier: MIT
! Bounded source-body REPL with validated scalar sessions. Explicit .run resets;
! queries execute only pending instructions and an ephemeral print, never replay.
! Source save/load does not execute code; .vars inspects retained scalar state.
module fi_repl
    use, intrinsic :: iso_fortran_env, only: int64, input_unit, output_unit, error_unit, iostat_end, iostat_eor
    use fi_repl_files, only: save_repl_source, load_repl_source, parse_repl_path
    use fi_limits, only: max_source_bytes
    use fi_ir, only: program_t, diagnostic_t, value_t, ty_integer, ty_real, ty_logical, ty_character
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program, scalar_session_t, reset_scalar_session, &
        execute_scalar_session, validate_scalar_session_program, validate_scalar_session_query, inspect_scalar_session, inspect_session_array
    use fi_repl_editor, only: edit_repl_body, list_repl_body
    use fi_runtime, only: scalar_session_tainted, grow_scalar_session
    use fi_repl_growth_source,only:stage_scalar_declaration
    implicit none
    private
    public :: run_repl
    integer, parameter :: line_limit=4096, line_count_limit=10000
    character(*), parameter :: header='program repl_session'//achar(10)//'implicit none'//achar(10)
    character(*), parameter :: footer='end program repl_session'//achar(10)
contains
    subroutine run_repl(status,max_steps,show_prompt,show_banner,prompt_text,defer_check)
        integer, intent(out) :: status
        integer(int64), intent(in), optional :: max_steps
        logical, intent(in), optional :: show_prompt,show_banner,defer_check
        character(*), intent(in), optional :: prompt_text
        character(:), allocatable :: body,next,source,command,prompt,path,message,actual,loaded
        character(line_limit+1) :: line
        integer :: ios,n,nlines,alloc_status,j,loaded_lines,inspection_mode,names_count
        character(63) :: inspection_names(128)
        integer(int64) :: steps
        logical :: prompts,banner,ended,too_long,layout_frozen,nonresumable,defer
        logical :: edit_requires_run,handled,must_gate,completed_ok
        type(scalar_session_t) :: session
        status=0; steps=1000000_int64; prompts=.true.; banner=.true.
        if(present(max_steps)) steps=max_steps
        if(present(show_prompt)) prompts=show_prompt
        if(present(show_banner)) banner=show_banner
        defer=.false.
        if(present(defer_check))defer=defer_check
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
        body=''; nlines=0; layout_frozen=.false.; nonresumable=.false.; edit_requires_run=.false.
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
            if(command=='.save'.or.index(command,'.save ')==1) then
                path='';message=''
                if(len(command)>5)call parse_repl_path(command(7:),path,message)
                if(len(message)==0)call save_repl_source(header//body//footer,path,actual,message)
                if(len(message)>0)then
                    call repl_error(message,status)
                else
                    write(output_unit,'(a)',iostat=ios)'Saved source to '//actual
                    status=0
                    if(ios/=0)status=2
                end if
                if(ended)return
                cycle
            end if
            if(command=='.load'.or.index(command,'.load ')==1) then
                call parse_repl_path(command(6:),path,message)
                if(len(message)==0)call load_repl_source(path,header,footer,loaded,loaded_lines,message)
                if(len(message)>0)then
                    call repl_error(message,status)
                else
                    call move_alloc(loaded,body);nlines=loaded_lines
                    layout_frozen=.false.;nonresumable=.false.;status=0
                    call reset_scalar_session(session)
                end if
                if(ended)return
                cycle
            end if
            call edit_repl_body(command,body,line_limit,line_count_limit, &
                max_source_bytes-len(header)-len(footer),handled,next,loaded_lines,message)
            if(handled)then
                if(len(message)>0)then
                    call repl_error(message,status)
                else
                    must_gate=edit_requires_run.or.layout_frozen.or.nonresumable.or.scalar_session_tainted(session)
                    call move_alloc(next,body);nlines=loaded_lines
                    call reset_scalar_session(session)
                    layout_frozen=.false.;nonresumable=.false.;edit_requires_run=must_gate;status=0
                end if
                if(ended)return
                cycle
            end if
            call parse_inspection_command(command,inspection_mode,inspection_names,names_count,message)
            if(inspection_mode/=0)then
                if(len(message)>0)then
                    call repl_error(message,status)
                else if(edit_requires_run)then
                    call repl_error('source edited; use .run to rebuild state',status)
                else if(nonresumable)then
                    call repl_error('buffer ran outside scalar session subset; use .clear before inspection',status)
                else
                    call vars_buffer(body,steps,session,layout_frozen,status,inspection_mode,inspection_names,names_count)
                end if
                if(ended)return
                cycle
            end if
            select case(command)
            case('.quit!')
                return
            case('.quit')
                if(len(body)==0)return
                call save_repl_source(header//body//footer,'',actual,message)
                if(len(message)>0)then
                    call repl_error(message,status)
                else
                    write(output_unit,'(a)',iostat=ios)'Saved source to '//actual
                    if(ios/=0)status=2
                    return
                end if
            case('.clear')
                body=''; nlines=0; status=0; layout_frozen=.false.; nonresumable=.false.; edit_requires_run=.false.
                call reset_scalar_session(session)
            case('.help')
                write(output_unit,'(a)',iostat=ios) &
                    '. or .run: compile and run the entire buffer with fresh state', &
                    '.list: numbered editable body; .list -n: plain wrapped source; .help: show this help', &
                    '.del n[:m], .ins n text, .rep n text: edit body; executed edits require explicit .run.', &
                    '.clear: clear body/state; .quit: autosave source and exit; .quit!: exit without saving', &
                    '.save [file]: save without overwrite; .load file: load REPL-saved source without running', &
                    'Supported assignments, PRINT and complete IF/DO/SELECT execute immediately; queries never replay prior effects.', &
                    'Queries: bounded scalar/array arithmetic, seven elemental math intrinsics, SIZE/LBOUND/UBOUND, and seven array reductions.', &
                    'Persistent state: intrinsic scalars, fixed rank-one numeric/logical arrays, forward IF/SELECT, named/counting/WHILE/bare DO and EXIT/CYCLE; runtime errors taint it.', &
                    '.vars [names]: values; .info [names]: type/kind/rank; .shapes/.sizes [names]: array extents/counts.', &
                    'Inspection executes pending statements once; invalid filters do not execute; arrays show at most 16 elements.', &
                    'After execution, one fresh plain INTEGER/REAL/LOGICAL :: name may be hoisted without replay.', &
                    'Other declarations stay frozen. Growth refuses continued specifications. Constructors: at most 256 items.', &
                    'EOF does not run/save. .run resets state. Source files are not runtime-state snapshots.', &
                    'Limits: 4096 bytes per line, 10000 body lines, 1048576 total source bytes.'
                if(ios/=0) then
                    status=2; return
                end if
            case('.','.run','.list','.list -n')
                allocate(character(len(header)+len(body)+len(footer))::source,stat=alloc_status)
                if(alloc_status/=0) then
                    call repl_error('cannot allocate source buffer',status); status=2; return
                end if
                source=header//body//footer
                if(command=='.list'.or.command=='.list -n') then
                    call list_repl_body(output_unit,header,body,footer,command=='.list',ios)
                    if(ios/=0) then
                        status=2; return
                    end if
                else
                    call run_buffer(source,steps,session,layout_frozen,nonresumable,status,completed_ok)
                    if(completed_ok)edit_requires_run=.false.
                end if
                deallocate(source)
            case default
                if(is_expression_line(command).and..not.continued_body(body)) then
                    if(edit_requires_run)then
                        call repl_error('source edited; use .run to rebuild state',status)
                    else if(nonresumable) then
                        call repl_error('buffer ran outside scalar session subset; use .clear before querying',status)
                    else
                        call query_buffer(body,command,steps,session,layout_frozen,status)
                    end if
                    if(ended) return
                    cycle
                end if
                if(is_declaration_line(command).and.(layout_frozen.or.edit_requires_run.or. &
                   nonresumable.or.scalar_session_tainted(session)))then
                    if(edit_requires_run)then
                        call repl_error('source edited; use .run before declaration growth',status)
                    else if(nonresumable)then
                        call repl_error('buffer ran outside retained subset; use .clear before declaration growth',status)
                    else if(scalar_session_tainted(session))then
                        call repl_error('session tainted; use .run or .clear before declaration growth',status)
                    else
                        call grow_buffer_declaration(body,line(:n),nlines,session,status)
                    end if
                    if(ended)return
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
                    if(.not.edit_requires_run.and..not.defer.and..not.nonresumable.and.is_immediate_line(command)) then
                        call try_immediate_buffer(body,steps,session,layout_frozen,status)
                    end if
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

    subroutine run_buffer(source,steps,session,frozen,nonresumable,status,completed_ok)
        character(*),intent(in)::source
        integer(int64),intent(in)::steps
        type(scalar_session_t),intent(inout)::session
        logical,intent(inout)::frozen,nonresumable
        integer,intent(out)::status
        logical,intent(out)::completed_ok
        type(program_t)::prog
        type(diagnostic_t)::diag,admission
        completed_ok=.false.
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
        completed_ok=diag%code==0.and.status==0
    end subroutine

    ! Compile/admit the complete prefix before any effects. Incomplete constructs
    ! or programs outside the scalar subset stay buffered for explicit .run.
    subroutine try_immediate_buffer(body,steps,session,frozen,status)
        character(*),intent(in)::body
        integer(int64),intent(in)::steps
        type(scalar_session_t),intent(inout)::session
        logical,intent(inout)::frozen
        integer,intent(inout)::status
        type(program_t)::prog
        type(diagnostic_t)::diag
        call compile_buffer(header//body//footer,prog,diag)
        if(diag%code/=0)return
        call validate_scalar_session_program(prog,diag)
        if(diag%code/=0)return
        call execute_scalar_session(session,prog,diag,max_steps=steps)
        if(diag%code==0)frozen=.true.
        call report_diagnostic(diag,status)
    end subroutine

    subroutine grow_buffer_declaration(body,line,nlines,session,status)
        ! No execution: compile and stage both source versions before atomic state
        ! extension. A failed transaction leaves the visible body byte-for-byte intact.
        character(:),allocatable,intent(inout)::body
        character(*),intent(in)::line
        integer,intent(inout)::nlines
        type(scalar_session_t),intent(inout)::session
        integer,intent(out)::status
        character(:),allocatable::original_source,candidate_source,staged
        type(program_t)::original,candidate
        type(diagnostic_t)::diag
        integer::ios,insertion
        allocate(character(len(header)+len(body)+len(footer))::original_source,stat=ios)
        if(ios/=0)then
            call repl_error('cannot allocate original growth source',status);return
        end if
        original_source(:len(header))=header
        original_source(len(header)+1:len(header)+len(body))=body
        original_source(len(header)+len(body)+1:)=footer
        call compile_buffer(original_source,original,diag)
        if(diag%code==0)call validate_scalar_session_program(original,diag)
        if(diag%code/=0)then
            call report_diagnostic(diag,status);return
        end if
        call stage_scalar_declaration(body,line,original,2,max_source_bytes-len(header)-len(footer), &
            line_count_limit,staged,insertion,diag)
        if(diag%code/=0)then
            call report_diagnostic(diag,status);return
        end if
        allocate(character(len(header)+len(staged)+len(footer))::candidate_source,stat=ios)
        if(ios/=0)then
            call repl_error('cannot allocate candidate growth source',status);return
        end if
        candidate_source(:len(header))=header
        candidate_source(len(header)+1:len(header)+len(staged))=staged
        candidate_source(len(header)+len(staged)+1:)=footer
        call compile_buffer(candidate_source,candidate,diag)
        if(diag%code==0)call validate_scalar_session_program(candidate,diag)
        if(diag%code==0)call grow_scalar_session(session,original,candidate,insertion,diag)
        if(diag%code/=0)then
            call report_diagnostic(diag,status);return
        end if
        call move_alloc(staged,body)
        nlines=nlines+1;status=0
    end subroutine

    logical function is_immediate_line(line) result(immediate)
        character(*),intent(in)::line
        character::quote,c
        integer::i,depth
        immediate=.false.
        if(is_declaration_line(line))return
        ! A complete IF is admitted atomically; incomplete source fails compilation
        ! without executing its already-entered assignment/PRINT lines.
        if(first_word(line)=='if'.or.first_word(line)=='endif'.or.first_word(line)=='enddo'.or.first_word(line)=='endselect'.or.first_word(line)=='end')then
            immediate=.true.;return
        end if
        if(first_word(line)=='print')then
            immediate=.true.;return
        end if
        if(len(first_word(line))==0)return
        quote=' ';depth=0;i=1
        do while(i<=len_trim(line))
            c=line(i:i)
            if(quote/=' ')then
                if(c==quote)then
                    if(i<len_trim(line))then
                        if(line(i+1:i+1)==quote)then
                            i=i+2;cycle
                        end if
                    end if
                    quote=' '
                end if
            else
                select case(c)
                case("'",'"')
                    quote=c
                case('!',';')
                    return
                case('(')
                    depth=depth+1
                case(')')
                    depth=depth-1
                case('=')
                    if(depth==0)then
                        if(i<len_trim(line))then
                            if(line(i+1:i+1)=='='.or.line(i+1:i+1)=='>')return
                        end if
                        if(i>1)then
                            if(index('/<>',line(i-1:i-1))/=0)return
                        end if
                        immediate=.true.;return
                    end if
                end select
            end if
            i=i+1
        end do
    end function

    function inspection_lower(text) result(lower)
        character(*),intent(in)::text
        character(len(text))::lower
        integer::i,n
        lower=text
        do i=1,len(text)
            n=iachar(text(i:i))
            if(n>=65.and.n<=90)lower(i:i)=achar(n+32)
        end do
    end function

    subroutine parse_inspection_command(command,mode,names,n,message)
        character(*),intent(in)::command
        integer,intent(out)::mode,n
        character(63),intent(out)::names(128)
        character(:),allocatable,intent(out)::message
        integer::i,j,k,c
        character(:),allocatable::verb,token
        mode=0;n=0;names='';message=''
        j=1
        do while(j<=len(command))
            if(command(j:j)==' '.or.command(j:j)==achar(9))exit
            j=j+1
        end do
        verb=command(:j-1)
        select case(verb)
        case('.vars');mode=1
        case('.info');mode=2
        case('.shapes');mode=3
        case('.sizes');mode=4
        case default;return
        end select
        i=j
        do while(i<=len(command))
            if(command(i:i)==' '.or.command(i:i)==achar(9))then
                i=i+1;cycle
            end if
            j=i
            do while(j<=len(command))
                if(command(j:j)==' '.or.command(j:j)==achar(9))exit
                j=j+1
            end do
            token=inspection_lower(command(i:j-1))
            if(len(token)>63.or.n==128)then
                message='inspection allows at most 128 names of at most 63 characters';return
            end if
            do k=1,len(token)
                c=iachar(token(k:k))
                if(c>=97.and.c<=122)cycle
                if(k>1.and.((c>=48.and.c<=57).or.c==95))cycle
                message='inspection expects whitespace-separated variable names';return
            end do
            n=n+1;names(n)=token;i=j
        end do
    end subroutine

    subroutine vars_buffer(body,steps,session,frozen,status,mode,names,names_count)
        character(*),intent(in)::body
        integer(int64),intent(in)::steps
        type(scalar_session_t),intent(inout)::session
        logical,intent(inout)::frozen
        integer,intent(out)::status
        integer,intent(in)::mode,names_count
        character(63),intent(in)::names(128)
        integer,allocatable::selected(:)
        integer::k,nselected,found,kind_number,alloc_status
        character(12)::type_name
        integer(int64)::extent
        type(program_t)::prog
        type(diagnostic_t)::diag
        type(value_t)::value
        type(value_t),allocatable::elements(:)
        logical,allocatable::element_defined(:)
        integer(int64)::lower
        character(256)::label
        logical::defined
        integer::i,j,ios
        call compile_buffer(header//body//footer,prog,diag)
        if(diag%code==0) call validate_scalar_session_program(prog,diag)
        if(diag%code/=0)then
            call report_diagnostic(diag,status);return
        end if
        allocate(selected(max(prog%ns,names_count)),stat=alloc_status)
        if(alloc_status/=0)then
            call repl_error('cannot allocate inspection selection',status);status=2;return
        end if
        nselected=0
        if(names_count==0)then
            do i=1,prog%ns
                if(mode>=3.and.prog%symbols(i)%rank==0)cycle
                nselected=nselected+1;selected(nselected)=i
            end do
        else
            do k=1,names_count
                found=0
                do i=1,prog%ns
                    if(inspection_lower(trim(prog%symbols(i)%name))==trim(names(k)))found=i
                end do
                if(found==0)then
                    call repl_error('unknown inspection name: '//trim(names(k)),status);return
                end if
                nselected=nselected+1;selected(nselected)=found
            end do
        end if
        ! Admission, all names and prefix comparison precede pending effects; never replay.
        if(diag%code==0) call execute_scalar_session(session,prog,diag,max_steps=steps)
        if(diag%code/=0) then
            call report_diagnostic(diag,status);return
        end if
        frozen=.true.;status=0;ios=0
        if(nselected==0)then
            if(mode>=3)then
                write(output_unit,'(a)',iostat=ios) '(no arrays)'
            else
                write(output_unit,'(a)',iostat=ios) '(no variables)'
            end if
        end if
        do k=1,nselected
            i=selected(k)
            if(ios/=0)exit
            if(mode==2)then
                kind_number=prog%symbols(i)%real_kind
                if(prog%symbols(i)%typ==ty_character)kind_number=kind('a')
                select case(prog%symbols(i)%typ)
                case(ty_integer);type_name='INTEGER'
                case(ty_real);type_name='REAL'
                case(ty_logical);type_name='LOGICAL'
                case(ty_character);type_name='CHARACTER'
                end select
                write(output_unit,'(a,a,a,i0,a,i0)',iostat=ios) trim(prog%symbols(i)%name)//' : ', &
                    trim(type_name),' kind=',kind_number,' rank=',prog%symbols(i)%rank
                if(prog%symbols(i)%typ==ty_character.and.ios==0) &
                    write(output_unit,'(a,i0)',iostat=ios)'  len=',prog%symbols(i)%character_len
                if(ios/=0)exit
            else if(mode>=3)then
                if(prog%symbols(i)%rank==0)then
                    write(output_unit,'(a)',iostat=ios)trim(prog%symbols(i)%name)//': scalar'
                else
                    extent=max(0_int64,prog%symbols(i)%upper_bound-prog%symbols(i)%lower_bound+1)
                    write(output_unit,'(a,i0)',iostat=ios)trim(prog%symbols(i)%name)//': ',extent
            end if
                cycle
            end if
            if(prog%symbols(i)%rank==1)then
                call inspect_session_array(session,i,elements,element_defined,lower,diag)
                if(diag%code/=0)then
                    call report_diagnostic(diag,status);return
                end if
                write(output_unit,'(a,i0,a,i0,a,i0,a,i0,a)',iostat=ios) &
                    trim(prog%symbols(i)%name)//'(',lower,':',prog%symbols(i)%upper_bound, &
                    ') = <',count(element_defined),'/',size(elements),' defined>'
                do j=1,min(16,size(elements))
                    if(ios/=0)exit
                    write(label,'(a,i0,a)')trim(prog%symbols(i)%name)//'(',lower+j-1,') = '
                    if(.not.element_defined(j))then
                        write(output_unit,'(a)',iostat=ios) trim(label)//' <undefined>'
                    else
                        value=elements(j)
                        select case(value%tag)
                        case(ty_integer)
                            write(output_unit,'(a,1x,i0)',iostat=ios)trim(label),value%i
                        case(ty_real)
                            write(output_unit,'(a,1x,g0)',iostat=ios)trim(label),value%r
                        case(ty_logical)
                            write(output_unit,'(a,1x,l1)',iostat=ios)trim(label),value%l
                        end select
                    end if
                end do
                if(size(elements)>16.and.ios==0)write(output_unit,'(a)',iostat=ios)'  ... (first 16 elements shown)'
                cycle
            end if
            call inspect_scalar_session(session,i,value,defined,diag)
            if(diag%code/=0)then
                call report_diagnostic(diag,status);return
            end if
            if(.not.defined)then
                write(output_unit,'(a)',iostat=ios) trim(prog%symbols(i)%name)//' = <undefined>'
            else
                select case(value%tag)
                case(ty_integer)
                    write(output_unit,'(a,i0)',iostat=ios) trim(prog%symbols(i)%name)//' = ',value%i
                case(ty_real)
                    write(output_unit,'(a,g0)',iostat=ios) trim(prog%symbols(i)%name)//' = ',value%r
                case(ty_logical)
                    write(output_unit,'(a,l1)',iostat=ios) trim(prog%symbols(i)%name)//' = ',value%l
                case(ty_character)
                    write(output_unit,'(a)',iostat=ios) trim(prog%symbols(i)%name)//' = '//inspection_string(value%s)
                end select
            end if
        end do
        if(ios/=0)status=2
    end subroutine

    function inspection_string(value) result(quoted)
        character(*),intent(in)::value
        character(:),allocatable::quoted,buffer
        integer::i,n,k
        allocate(character(2*len(value)+2)::buffer)
        buffer(1:1)='"';n=1
        do i=1,len(value)
            k=iachar(value(i:i))
            select case(k)
            case(34,92)
                buffer(n+1:n+1)=value(i:i);buffer(n+2:n+2)=value(i:i);n=n+2
            case(9,10,13)
                buffer(n+1:n+1)=achar(92)
                if(k==9)buffer(n+2:n+2)='t'
                if(k==10)buffer(n+2:n+2)='n'
                if(k==13)buffer(n+2:n+2)='r'
                n=n+2
            case default
                buffer(n+1:n+1)=value(i:i);n=n+1
            end select
        end do
        buffer(n+1:n+1)='"';quoted=buffer(:n+1)
    end function

    subroutine query_buffer(body,expression,steps,session,frozen,status)
        character(*),intent(in)::body,expression
        integer(int64),intent(in)::steps
        type(scalar_session_t),intent(inout)::session
        logical,intent(inout)::frozen
        integer,intent(out)::status
        type(program_t)::base,query
        type(diagnostic_t)::diag
        character(:),allocatable::source,query_source,clean_expression
        integer::ios
        logical::valid
        call normalize_query(expression,clean_expression,valid)
        if(.not.valid) then
            call repl_error('query must be one balanced expression without statement separators',status); return
        end if
        if(len(header)+len(body)+len(footer)+len(clean_expression)+12>max_source_bytes) then
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
        allocate(character(len(header)+len(body)+len(clean_expression)+12+len(footer))::query_source,stat=ios)
        if(ios/=0) then
            call repl_error('cannot allocate query source',status); status=2; return
        end if
        query_source=header//body//'print *, ('//clean_expression//')'//achar(10)//footer
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

    subroutine normalize_query(line,expression,valid)
        character(*),intent(in)::line
        character(:),allocatable,intent(out)::expression
        logical,intent(out)::valid
        character::quote,c
        integer::i,depth,last
        valid=.false.;expression='';quote=' ';depth=0;last=len_trim(line);i=1
        do while(i<=last)
            c=line(i:i)
            if(quote/=' ') then
                if(c==quote) then
                    if(i<last) then
                        if(line(i+1:i+1)==quote) then
                            i=i+2;cycle
                        end if
                    end if
                    quote=' '
                end if
            else
                select case(c)
                case("'",'"')
                    quote=c
                case('!')
                    last=i-1;exit
                case(';')
                    return
                case('(')
                    depth=depth+1
                case(')')
                    depth=depth-1
                    if(depth<0)return
                case(',')
                    if(depth==0)return
                end select
            end if
            i=i+1
        end do
        if(quote/=' '.or.depth/=0)return
        expression=trim(line(:last))
        valid=len_trim(expression)>0
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
        integer::i,k,depth
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
             'elseif','endif','enddo','do','select','case','call','print','write','read','allocate','deallocate', &
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
        quote=' ';i=1;depth=0
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
                if(c=='(')depth=depth+1
                if(c==')')depth=depth-1
                if(c=='='.and.depth==0) then
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
