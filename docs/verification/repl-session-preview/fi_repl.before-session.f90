! SPDX-License-Identifier: MIT
! Deliberately bounded source-body REPL. Each run creates fresh compiler/runtime
! state. No evaluation replay, inspection, implicit saves or host file access.
module fi_repl
    use, intrinsic :: iso_fortran_env, only: int64, input_unit, output_unit, error_unit, iostat_end, iostat_eor
    use fi_limits, only: max_source_bytes
    use fi_ir, only: program_t, diagnostic_t
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
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
        logical :: prompts,banner,ended,too_long
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
        body=''; nlines=0
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
                body=''; nlines=0; status=0
            case('.help')
                write(output_unit,'(a)',iostat=ios) &
                    '. or .run: compile and run the entire buffer with fresh state', &
                    '.list: show the standard Fortran wrapper and buffered body; .help: show this help', &
                    '.clear: clear the body and last error; .quit or .quit!: exit without saving', &
                    'No automatic execution. Checks occur only on .run. EOF does not run or save.', &
                    'Body only; program/module units, load/save, expression queries and .vars are unsupported.', &
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
                    call run_buffer(source,steps,status)
                end if
                deallocate(source)
            case default
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

    subroutine run_buffer(source,steps,status)
        character(*),intent(in)::source
        integer(int64),intent(in)::steps
        integer,intent(out)::status
        type(program_t)::prog
        type(diagnostic_t)::diag
        integer::ios
        call parse_subset(source,prog,diag)
        if(diag%code==0) call verify_frontend(source,prog,diag)
        if(diag%code==0) call execute_program(prog,diag,max_steps=steps,program_name='<repl>')
        status=diag%code
        if(diag%code==3) then
            status=diag%stop_status
            write(error_unit,'(a)',iostat=ios) diag%message
        else if(diag%code/=0) then
            write(error_unit,'(a,i0,a,i0,a,a)',iostat=ios) '<repl>:',diag%line,':',diag%column,': ',diag%message
        else
            ios=0
        end if
        if(ios/=0) status=2
    end subroutine
end module
