! SPDX-License-Identifier: MIT
! Conservative physical-boundary proof for one-line retained scalar declarations.
module fi_repl_growth_source
    use fi_ir,only:program_t,diagnostic_t
    implicit none
    private
    public::stage_scalar_declaration,plain_scalar_declaration
contains
    logical function space(c)
        character,intent(in)::c
        space=c==' '.or.c==achar(9)
    end function
    logical function letter(c)
        character,intent(in)::c
        integer::k
        k=iachar(c);letter=(k>=65.and.k<=90).or.(k>=97.and.k<=122)
    end function
    logical function name_char(c)
        character,intent(in)::c
        integer::k
        k=iachar(c);name_char=letter(c).or.c=='_'.or.(k>=48.and.k<=57)
    end function
    function word(text,pos) result(name)
        character(*),intent(in)::text
        integer,intent(inout)::pos
        character(:),allocatable::name
        integer::start,j,k
        do while(pos<=len(text))
            if(.not.space(text(pos:pos)))exit
            pos=pos+1
        end do
        start=pos
        do while(pos<=len(text))
            if(.not.name_char(text(pos:pos)))exit
            pos=pos+1
        end do
        name=text(start:pos-1)
        do j=1,len(name)
            k=iachar(name(j:j));if(k>=65.and.k<=90)name(j:j)=achar(k+32)
        end do
    end function
    logical function plain_scalar_declaration(line) result(ok)
        character(*),intent(in)::line
        character(:),allocatable::typ,name
        integer::pos,start
        ok=.false.;pos=1;typ=word(line,pos)
        if(typ/='integer'.and.typ/='real'.and.typ/='logical')return
        do while(pos<=len(line))
            if(.not.space(line(pos:pos)))exit
            pos=pos+1
        end do
        if(pos+1>len(line))return
        if(line(pos:pos+1)/='::')return
        pos=pos+2
        do while(pos<=len(line))
            if(.not.space(line(pos:pos)))exit
            pos=pos+1
        end do
        if(pos>len(line))return
        if(.not.letter(line(pos:pos)))return
        start=pos;name=word(line,pos)
        if(len(name)<1.or.len(name)>63)return
        ! Avoid names the REPL would classify as statements rather than queries.
        select case(name)
        case('integer','real','logical','double','character','complex','type','class','implicit', &
             'parameter','dimension','save','allocatable','pointer','target','external','intrinsic', &
             'optional','intent','public','private','use','import','program','end','endif','enddo', &
             'subroutine','function','module','contains','if','then','else','elseif','do','select', &
             'case','call','print','write','read','allocate','deallocate','return','stop','error', &
             'exit','cycle','where','elsewhere','forall','block','associate','backspace','inquire', &
             'open','close','rewind','flush','format','data','continue')
            return
        end select
        do while(pos<=len(line))
            if(.not.space(line(pos:pos)))exit
            pos=pos+1
        end do
        if(pos<=len(line))then
            if(line(pos:pos)/='!')return
        end if
        ok=.true.
    end function
    logical function complete_spec_line(line) result(ok)
        character(*),intent(in)::line
        character::quote,c
        character(:),allocatable::first
        integer::j,pos
        ok=.false.;quote=' ';j=1
        do while(j<=len(line))
            c=line(j:j)
            if(quote/=' ')then
                if(c==quote)then
                    if(j<len(line))then
                        if(line(j+1:j+1)==quote)then
                            j=j+2;cycle
                        end if
                    end if
                    quote=' '
                end if
            else
                if(c=='!')exit
                if(c=='&'.or.c==';')return
                if(c=="'".or.c=='"')quote=c
            end if
            j=j+1
        end do
        if(quote/=' ')return
        pos=1;first=word(line,pos)
        if(len(first)==0)then
            ! word() consumed only horizontal whitespace, never punctuation.
            if(pos>len(line))then
                ok=.true.
            else
                ok=line(pos:pos)=='!'
            end if
            return
        end if
        select case(first)
        case('integer','real','logical','character','double','implicit')
            ok=.true.
        end select
    end function
    subroutine stage_scalar_declaration(body,line,prog,header_lines,max_bytes,max_lines,staged,insertion_line,diag)
        character(*),intent(in)::body,line
        type(program_t),intent(in)::prog
        integer,intent(in)::header_lines,max_bytes,max_lines
        character(:),allocatable,intent(out)::staged
        integer,intent(out)::insertion_line
        type(diagnostic_t),intent(inout)::diag
        integer::count,j,boundary,start,finish,body_line,at,ios
        insertion_line=0
        if(diag%code/=0)return
        if(.not.plain_scalar_declaration(line))then
            call fail('growth requires one plain default INTEGER/REAL/LOGICAL :: fresh_name line');return
        end if
        if(index(line,achar(10))/=0.or.index(line,achar(13))/=0.or.index(line,achar(0))/=0)then
            call fail('declaration growth requires one physical line');return
        end if
        count=0
        do j=1,len(body)
            if(body(j:j)==achar(10))count=count+1
        end do
        if(len(body)>0)then
            if(body(len(body):)/=achar(10))then
                call fail('declaration insertion requires complete physical source lines');return
            end if
        end if
        if(count>=max_lines.or.len(line)+1>max_bytes-len(body))then
            call fail('source buffer limit exceeded; declaration discarded');return
        end if
        boundary=header_lines+count+1
        do j=1,prog%nc
            if(prog%code(j)%line<header_lines+1.or.prog%code(j)%line>header_lines+count)then
                call fail('cannot prove executable source boundary');return
            end if
            boundary=min(boundary,prog%code(j)%line)
        end do
        start=1;body_line=header_lines+1
        do while(body_line<boundary)
            finish=index(body(start:),achar(10))+start-1
            if(finish<start)then
                call fail('cannot prove source statement boundary');return
            end if
            if(.not.complete_spec_line(body(start:finish-1)))then
                call fail('growth requires a single-line specification region; use .clear or edit and .run');return
            end if
            start=finish+1;body_line=body_line+1
        end do
        at=start
        allocate(character(len(body)+len(line)+1)::staged,stat=ios)
        if(ios/=0)then
            call fail('cannot allocate declaration source transaction');return
        end if
        staged(:at-1)=body(:at-1)
        staged(at:at+len(line)-1)=line
        staged(at+len(line):at+len(line))=achar(10)
        staged(at+len(line)+1:)=body(at:)
        insertion_line=boundary
    contains
        subroutine fail(message)
            character(*),intent(in)::message
            diag%code=1;diag%message=message;diag%line=0;diag%column=0
        end subroutine
    end subroutine
end module
