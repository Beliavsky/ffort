! SPDX-License-Identifier: MIT
module fi_driver
    use, intrinsic :: iso_fortran_env, only: int64, error_unit
    use, intrinsic :: iso_c_binding, only: c_int, c_char, c_null_char
    use fi_ir
    use fi_repl, only: run_repl
    use fi_limits, only: max_source_bytes
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program, input_unit_t, validate_input_units
    implicit none
    private
    public :: compile_program, run_cli
    interface
        integer(c_int) function stdin_is_terminal() bind(C,name='fi_stdin_is_terminal')
            import c_int
        end function
        integer(c_int) function read_stdin_source(buffer,capacity,length) bind(C,name='fi_read_stdin_source')
            import c_int,c_char
            character(kind=c_char),intent(out)::buffer(*)
            integer(c_int),value::capacity
            integer(c_int),intent(out)::length
        end function
        integer(c_int) function load_input_bytes(path,buffer,capacity,length) bind(C,name='fi_load_input_file')
            import c_int,c_char
            character(kind=c_char),intent(in)::path(*)
            character(kind=c_char),intent(out)::buffer(*)
            integer(c_int),value::capacity
            integer(c_int),intent(out)::length
        end function
    end interface
contains
    subroutine compile_program(source,prog,diag)
        character(*),intent(in)::source
        type(program_t),intent(out)::prog
        type(diagnostic_t),intent(out)::diag
        call parse_subset(source,prog,diag)
        if(diag%code/=0) return
        call verify_frontend(source,prog,diag)
    end subroutine
    subroutine run_cli(status)
        integer,intent(out)::status
        character(:),allocatable::arg,filename,source,prompt
        character(4096)::buf
        character(32)::limit_text
        character(4096)::input_paths(32)
        type(input_unit_t)::inputs(32)
        integer::input_count,split,input_number,total_input,input_path_lengths(32)
        integer(c_int)::input_status,input_length
        character(kind=c_char),allocatable::input_buffer(:)
        type(program_t)::prog
        type(diagnostic_t)::diag
        integer::n,i,j,unit,ios,length
        integer(int64)::steps,nbytes
        logical::check,exists,force_repl,show_banner,terminal,batch_stdin,defer_check
        status=0; check=.false.; steps=1000000_int64; filename='';input_count=0
        force_repl=.false.; show_banner=.true.; prompt='> '; batch_stdin=.false.; defer_check=.false.
        terminal=stdin_is_terminal()/=0
        n=command_argument_count(); i=1
        do while(i<=n)
            call get_command_argument(i,buf,length=length,status=ios)
            if(ios/=0) then
                call fail(diag,'Command argument is too long'); exit
            end if
            arg=buf(:length)
            select case(arg)
            case('--help','-h')
                print '(a)', 'Usage: fortfront-interpreter [--check] [--max-steps N] [--input UNIT=PATH] [source.f90]'
                print '(a)', 'A bounded scalar and rank-one/rank-two array Fortran prototype. See README.md for the exact subset.'
                print '(a)', 'Input: explicit read-only regular files, up to 32 units; 1 MiB each and 4 MiB total. --check never opens them.'
                print '(a)', 'No file: terminal starts a source-buffer REPL; piped stdin is batch source. --repl forces REPL.'
                print '(a)', 'REPL options: --interactive, --nologo, --prompt TEXT, --defer-check. .help describes the initial bounded subset.'
                print '(a)', 'Exit status: 0 success, 1 source/options error, 2 runtime error.'
                return
            case('--version')
                print '(a)', 'fortfront-interpreter 0.56.0; FortFront 9a5896a + documented local patches'
                return
            case('--repl','--interactive')
                force_repl=.true.
            case('--defer-check')
                defer_check=.true.
            case('--nologo')
                show_banner=.false.
            case('--prompt')
                i=i+1
                if(i>n) then
                    call fail(diag,'--prompt needs text'); exit
                end if
                call get_command_argument(i,buf,length=length,status=ios)
                if(ios/=0.or.length>128) then
                    call fail(diag,'--prompt text exceeds 128 characters'); exit
                end if
                prompt=buf(:length)
            case('--check')
                check=.true.
            case('--input')
                i=i+1
                if(i>n.or.input_count>=32) then
                    call fail(diag,'--input needs UNIT=PATH; at most 32 units');exit
                end if
                call get_command_argument(i,buf,length=length,status=ios)
                if(ios/=0.or.length<3) then
                    call fail(diag,'--input needs a positive decimal UNIT=PATH');exit
                end if
                split=index(buf(:length),'=')
                if(split<2.or.split>=length) then
                    call fail(diag,'--input needs a positive decimal UNIT=PATH');exit
                end if
                do j=1,split-1
                    if(buf(j:j)<'0'.or.buf(j:j)>'9') exit
                end do
                if(j<split) then
                    call fail(diag,'--input unit must be a positive decimal INTEGER(4)');exit
                end if
                read(buf(:split-1),*,iostat=ios) input_number
                if(ios/=0) input_number=0
                if(input_number<=0) then
                    call fail(diag,'--input unit must be a positive decimal INTEGER(4)');exit
                end if
                do j=1,input_count
                    if(inputs(j)%unit==input_number) exit
                end do
                if(j<=input_count) then
                    call fail(diag,'duplicate --input unit');exit
                end if
                input_count=input_count+1
                inputs(input_count)%unit=input_number
                input_paths(input_count)=buf(split+1:length)
                input_path_lengths(input_count)=length-split
                inputs(input_count)%name=buf(split+1:length)
            case('--max-steps')
                i=i+1
                if(i>n) then
                    call fail(diag,'--max-steps needs a positive integer'); exit
                end if
                call get_command_argument(i,buf,length=length,status=ios)
                if(ios/=0 .or. length==0) then
                    call fail(diag,'Invalid --max-steps value'); exit
                end if
                do j=1,length
                    if(buf(j:j)<'0'.or.buf(j:j)>'9') exit
                end do
                if(j<=length) then
                    call fail(diag,'--max-steps needs a positive decimal integer'); exit
                end if
                read(buf(:length),*,iostat=ios) steps
                if(ios/=0) then
                    call fail(diag,'Invalid --max-steps value'); exit
                end if
                if(steps<=0) then
                    call fail(diag,'--max-steps must be positive'); exit
                end if
            case default
                if(len(arg)==0) then
                    call fail(diag,'Empty source filename'); exit
                end if
                if(arg(1:1)=='-') then
                    call fail(diag,'Unknown option: '//arg); exit
                end if
                if(len(filename)/=0) then
                    call fail(diag,'Specify exactly one source file'); exit
                end if
                filename=arg
            end select
            i=i+1
        end do
        if(diag%code==0.and.(force_repl.or.(len(filename)==0.and.terminal))) then
            if(len(filename)>0.or.check.or.input_count>0) then
                call fail(diag,'REPL does not accept a source filename, --check or --input; use batch mode')
            else
                call run_repl(status,steps,.true.,show_banner,prompt,defer_check)
                return
            end if
        end if
        if(diag%code==0.and.defer_check) call fail(diag,'--defer-check requires REPL mode')
        if(diag%code==0.and.len(filename)==0) then
            batch_stdin=.true.; filename='<stdin>'
            allocate(input_buffer(max_source_bytes),stat=ios)
            if(ios/=0) then
                call fail(diag,'Cannot allocate bounded stdin source buffer')
            else
                input_status=read_stdin_source(input_buffer,int(max_source_bytes,c_int),input_length)
                if(input_status==2) then
                    call fail(diag,'Stdin source exceeds 1048576-byte limit')
                else if(input_status/=0) then
                    call fail(diag,'Cannot read complete stdin source')
                else
                    allocate(character(int(input_length))::source,stat=ios)
                    if(ios/=0) then
                        call fail(diag,'Cannot allocate stdin source')
                    else
                        do j=1,int(input_length)
                            source(j:j)=input_buffer(j)
                        end do
                    end if
                end if
                deallocate(input_buffer)
            end if
        end if
        if(diag%code==0.and..not.batch_stdin) then
            inquire(file=filename,exist=exists,size=nbytes,iostat=ios)
            if(ios/=0.or..not.exists) then
                call fail(diag,'Cannot read source file: '//filename)
            else if(nbytes<0) then
                call fail(diag,'Cannot determine source file size: '//filename)
            else if(nbytes>int(max_source_bytes,int64)) then
                write(limit_text,'(i0)') max_source_bytes
                call fail(diag,'Source file exceeds '//trim(limit_text)//'-byte limit')
            else
                length=int(nbytes)
                allocate(character(length)::source,stat=ios)
                if(ios/=0) then
                    call fail(diag,'Cannot allocate source buffer')
                end if
            end if
            if(diag%code==0) then
                open(newunit=unit,file=filename,status='old',action='read',access='stream', &
                     form='unformatted',iostat=ios)
                if(ios/=0) then
                    call fail(diag,'Cannot open source file: '//filename)
                else
                    if(length>0) read(unit,iostat=ios) source
                    close(unit)
                    if(ios/=0) call fail(diag,'Cannot read complete source file: '//filename)
                end if
            end if
        end if
        if(diag%code==0) call compile_program(source,prog,diag)
        ! Parse and compile first. Checking source never opens input bindings.
        if(diag%code==0.and..not.check.and.input_count>0) then
            allocate(input_buffer(1048576),stat=ios)
            if(ios/=0) call fail(diag,'Cannot allocate bounded input buffer')
            total_input=0
            do i=1,input_count
                if(diag%code/=0) exit
                input_status=load_input_bytes(input_paths(i)(:input_path_lengths(i))//c_null_char,input_buffer,1048576_c_int,input_length)
                select case(input_status)
                case(0)
                    total_input=total_input+int(input_length)
                    if(total_input>4194304) then
                        call fail(diag,'External input total byte limit exceeded (4194304)');exit
                    end if
                    allocate(character(int(input_length))::inputs(i)%data,stat=ios)
                    if(ios/=0) then
                        call fail(diag,'Cannot allocate bound input record');exit
                    end if
                    do j=1,int(input_length)
                        inputs(i)%data(j:j)=input_buffer(j)
                    end do
                case(1)
                    call fail(diag,'Cannot open explicit input file: '//trim(input_paths(i)))
                case(2)
                    call fail(diag,'Explicit input must be a regular file: '//trim(input_paths(i)))
                case(3)
                    call fail(diag,'Explicit input file exceeds 1048576-byte limit')
                case default
                    call fail(diag,'Cannot read complete stable input file: '//trim(input_paths(i)))
                end select
            end do
            if(allocated(input_buffer)) deallocate(input_buffer)
        end if
        if(diag%code==0.and..not.check) call execute_program(prog,diag,steps,program_name=filename,input_units=inputs(:input_count))
        ! The reusable runtime keeps its terse API diagnostic. Only the CLI
        ! knows which command-line budget was selected and how to change it.
        if(diag%code==2) then
            if(allocated(diag%message)) then
                if(diag%message=='execution step limit exceeded') then
                    write(limit_text,'(i0)') steps
                    diag%message=diag%message//' (current limit: '//trim(limit_text)// &
                        '); use --max-steps N to set the execution budget (positive 64-bit integer)'
                end if
            end if
        end if
        if(diag%code==3) then
            write(error_unit,'(a)') diag%message
            status=diag%stop_status;return
        end if
        if(diag%code/=0) then
            if(len(filename)==0) filename='<command>'
            write(error_unit,'(a,":",i0,":",i0,": ",a)') filename,diag%line,diag%column,diag%message
            status=diag%code
        end if
    end subroutine
end module
