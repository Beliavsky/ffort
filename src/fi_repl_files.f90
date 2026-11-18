! SPDX-License-Identifier: MIT
! Source-only REPL persistence. Never executes loaded/saved code or replaces files.
module fi_repl_files
    use, intrinsic :: iso_c_binding, only: c_int,c_char,c_null_char
    use fi_limits, only: max_source_bytes
    implicit none
    private
    public :: save_repl_source, load_repl_source, parse_repl_path
    interface
        integer(c_int) function load_input_bytes(path,buffer,capacity,length) bind(C,name='fi_load_input_file')
            import c_int,c_char
            character(kind=c_char),intent(in)::path(*)
            character(kind=c_char),intent(out)::buffer(*)
            integer(c_int),value::capacity
            integer(c_int),intent(out)::length
        end function
    end interface
contains
    subroutine parse_repl_path(argument,path,message)
        character(*),intent(in)::argument
        character(:),allocatable,intent(out)::path,message
        character(:),allocatable::arg
        integer::i
        arg=trim(adjustl(argument));path='';message=''
        if(len(arg)==0)then
            message='a filename is required';return
        end if
        if(arg(1:1)=='"'.or.arg(1:1)=="'")then
            if(len(arg)<2)then
                message='unterminated quoted filename';return
            end if
            if(arg(len(arg):)/=arg(1:1))then
                message='unterminated quoted filename';return
            end if
            path=arg(2:len(arg)-1)
            if(index(path,arg(1:1))/=0)then
                message='embedded filename quotes are unsupported';return
            end if
        else
            if(index(arg,' ')/=0.or.index(arg,achar(9))/=0)then
                message='quote filenames containing spaces; options are unsupported';return
            end if
            path=arg
        end if
        if(len(path)==0.or.len(path)>4096)then
            message='invalid filename length';return
        end if
        do i=1,len(path)
            if(iachar(path(i:i))<32.or.iachar(path(i:i))==127)then
                message='filename contains a control character';return
            end if
        end do
    end subroutine

    subroutine save_repl_source(source,requested,actual,message)
        character(*),intent(in)::source,requested
        character(:),allocatable,intent(out)::actual,message
        character(32)::number
        integer::unit,ios,close_status,k
        logical::exists
        actual='';message='';k=0
        if(len(source)>max_source_bytes)then
            message='source exceeds byte limit';return
        end if
        if(len(requested)>0)then
            actual=requested
            open(newunit=unit,file=actual,status='new',access='stream',form='unformatted',action='write',iostat=ios)
        else
            ios=1
            do k=0,99999
                actual='main.f90'
                if(k>0)then
                    write(number,'(i0)')k
                    actual='main'//trim(number)//'.f90'
                end if
                inquire(file=actual,exist=exists,iostat=ios)
                if(ios/=0)exit
                if(exists)cycle
                ! STATUS=NEW is the final collision guard; never truncate an existing file.
                open(newunit=unit,file=actual,status='new',access='stream',form='unformatted',action='write',iostat=ios)
                if(ios==0)exit
                inquire(file=actual,exist=exists,iostat=close_status)
                if(close_status/=0.or..not.exists)exit
            end do
        end if
        if(ios/=0.or.k>99999.and.len(requested)==0)then
            message='cannot create source file (existing files are never overwritten)';return
        end if
        write(unit,iostat=ios)source
        close(unit,iostat=close_status)
        if(ios/=0.or.close_status/=0)message='source write failed; partial new file may remain'
    end subroutine

    subroutine load_repl_source(path,header,footer,body,nlines,message)
        character(*),intent(in)::path,header,footer
        character(:),allocatable,intent(out)::body,message
        integer,intent(out)::nlines
        character(:),allocatable::raw,normalized
        character(kind=c_char),allocatable::input_buffer(:)
        integer(c_int)::input_status,input_length
        integer::ios,i,j,start,n
        body='';message='';nlines=0
        allocate(input_buffer(max_source_bytes),stat=ios)
        if(ios/=0)then
            message='cannot allocate bounded input buffer';return
        end if
        input_status=load_input_bytes(path//c_null_char,input_buffer,int(max_source_bytes,c_int),input_length)
        select case(input_status)
        case(0)
        case(1)
            message='cannot open regular source file (symlinks are unsupported)';return
        case(2)
            message='source must be a regular file';return
        case(3)
            message='source file exceeds byte limit';return
        case default
            message='cannot read complete stable source file';return
        end select
        allocate(character(int(input_length))::raw,stat=ios)
        if(ios/=0)then
            message='cannot allocate source file';return
        end if
        do i=1,int(input_length)
            raw(i:i)=input_buffer(i)
        end do
        deallocate(input_buffer)
        if(index(raw,achar(0))/=0)then
            message='NUL byte in source file';return
        end if
        ! Normalize Windows CRLF, but reject isolated CR to avoid hidden records.
        allocate(character(len(raw))::normalized,stat=ios)
        if(ios/=0)then
            message='cannot allocate normalized source';return
        end if
        i=1;j=0
        do while(i<=len(raw))
            if(raw(i:i)==achar(13))then
                if(i==len(raw))then
                    message='isolated carriage return in source';return
                end if
                if(raw(i+1:i+1)/=achar(10))then
                    message='isolated carriage return in source';return
                end if
                i=i+1
            end if
            j=j+1;normalized(j:j)=raw(i:i);i=i+1
        end do
        raw=normalized(:j)
        if(len(raw)<len(header)+len(footer))then
            message='load expects a source file saved by this REPL';return
        end if
        if(raw(:len(header))/=header.or.raw(len(raw)-len(footer)+1:)/=footer)then
            message='load expects the exact program repl_session wrapper saved by this REPL';return
        end if
        body=raw(len(header)+1:len(raw)-len(footer))
        n=len(body);start=1
        do i=1,n
            if(body(i:i)==achar(10))then
                if(i-start>4096)then
                    body='';message='loaded source line exceeds 4096 bytes';return
                end if
                nlines=nlines+1;start=i+1
            end if
        end do
        if(start/=n+1.or.nlines>10000)then
            body='';message='loaded body has incomplete record or exceeds 10000 lines';return
        end if
    end subroutine
end module
