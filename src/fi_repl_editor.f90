! SPDX-License-Identifier: MIT
module fi_repl_editor
    implicit none
    private
    public :: edit_repl_body, list_repl_body
contains
    subroutine edit_repl_body(command,body,max_line,max_lines,max_bytes,handled,replacement,nlines,message)
        character(*),intent(in)::command,body
        integer,intent(in)::max_line,max_lines,max_bytes
        logical,intent(out)::handled
        character(:),allocatable,intent(out)::replacement,message
        integer,intent(out)::nlines
        character(:),allocatable::verb,text
        integer::i,j,k,n,first,last,start,finish,ios
        logical::ok,colon
        handled=.false.;message='';nlines=0
        i=1
        do while(i<=len(command))
            if(space(command(i:i)))exit
            i=i+1
        end do
        verb=command(:i-1)
        if(verb/='.del'.and.verb/='.ins'.and.verb/='.rep')return
        handled=.true.
        n=0
        do j=1,len(body)
            if(body(j:j)==achar(10))n=n+1
        end do
        call skip_spaces(command,i)
        first=1;last=n;colon=.false.
        if(verb=='.del'.and.i<=len(command))then
            colon=command(i:i)==':'
        end if
        if(.not.colon)then
            call number(command,i,first,ok)
            if(.not.ok)then
                message='invalid edit line number';return
            end if
        end if
        if(verb=='.del')then
            call skip_spaces(command,i)
            if(i<=len(command))then
                if(command(i:i)/=':')then
                    message='unexpected text after deletion range';return
                end if
                i=i+1;call skip_spaces(command,i)
                if(i<=len(command))then
                    call number(command,i,last,ok)
                    if(.not.ok)then
                        message='invalid deletion range';return
                    end if
                end if
            else
                last=first
            end if
            call skip_spaces(command,i)
            if(i<=len(command).or.first<1.or.last<first.or.last>n)then
                message='deletion range outside editable body';return
            end if
            text='';nlines=n-(last-first+1)
        else
            if(i>len(command))then
                message='edit requires source text';return
            end if
            if(.not.space(command(i:i)))then
                message='line number must be followed by whitespace';return
            end if
            call skip_spaces(command,i)
            if(i>len(command))then
                message='edit requires source text';return
            end if
            text=command(i:)//achar(10)
            if(len(text)-1>max_line.or.index(text(:len(text)-1),achar(0))/=0.or. &
               index(text(:len(text)-1),achar(13))/=0.or.index(text(:len(text)-1),achar(10))/=0)then
                message='invalid or overlong edit text';return
            end if
            last=first
            if(verb=='.ins')last=first-1
            if(first<1.or.first>n+1.or.(verb=='.rep'.and.first>n))then
                message='edit line outside editable body';return
            end if
            nlines=n+1-(last-first+1)
        end if
        start=len(body)+1;finish=len(body)+1;k=1
        do j=1,len(body)
            if(k==first)then
                start=j;exit
            end if
            if(body(j:j)==achar(10))k=k+1
        end do
        if(last<first)then
            finish=start
        else
            k=1
            do j=1,len(body)
                if(body(j:j)==achar(10))then
                    if(k==last)then
                        finish=j+1;exit
                    end if
                    k=k+1
                end if
            end do
        end if
        if(nlines>max_lines.or.len(body)-(finish-start)+len(text)>max_bytes)then
            message='source buffer limit exceeded';return
        end if
        allocate(character(len(body)-(finish-start)+len(text))::replacement,stat=ios)
        if(ios/=0)then
            message='cannot allocate edited source';return
        end if
        replacement=body(:start-1)//text//body(finish:)
    end subroutine
    logical function space(c)
        character,intent(in)::c
        space=c==' '.or.c==achar(9)
    end function
    subroutine skip_spaces(s,i)
        character(*),intent(in)::s
        integer,intent(inout)::i
        do while(i<=len(s))
            if(.not.space(s(i:i)))exit
            i=i+1
        end do
    end subroutine
    subroutine number(s,i,value,ok)
        character(*),intent(in)::s
        integer,intent(inout)::i
        integer,intent(out)::value
        logical,intent(out)::ok
        integer::d,start
        start=i;value=0;ok=.false.
        do while(i<=len(s))
            d=iachar(s(i:i))-iachar('0')
            if(d<0.or.d>9)exit
            if(value>(huge(value)-d)/10)return
            value=value*10+d;i=i+1
        end do
        ok=i>start.and.value>0
    end subroutine
    subroutine list_repl_body(unit,header,body,footer,numbered,status)
        integer,intent(in)::unit
        character(*),intent(in)::header,body,footer
        logical,intent(in)::numbered
        integer,intent(out)::status
        integer::i,start,n
        status=0
        if(.not.numbered)then
            write(unit,'(a)',advance='no',iostat=status)header//body//footer
            return
        end if
        start=1
        do i=1,len(header)
            if(header(i:i)/=achar(10))cycle
            write(unit,'(a)',iostat=status) '       '//header(start:i-1)
            if(status/=0)return
            start=i+1
        end do
        start=1;n=1
        do i=1,len(body)
            if(body(i:i)/=achar(10))cycle
            write(unit,'(i5,2x,a)',iostat=status)n,body(start:i-1)
            if(status/=0)return
            n=n+1;start=i+1
        end do
        start=1
        do i=1,len(footer)
            if(footer(i:i)/=achar(10))cycle
            write(unit,'(a)',iostat=status) '       '//footer(start:i-1)
            if(status/=0)return
            start=i+1
        end do
    end subroutine
end module
