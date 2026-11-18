! SPDX-License-Identifier: MIT
program test_punctuation_literals
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(8),parameter::spellings(17)=[character(8)::'[',']','(',')','/',',',':','::','%','=','=>','+','-','//','**','.not.','.flip.']
    character(:),allocatable::source,q
    integer::i,j,n,checks
    checks=0
    do i=1,size(spellings)
        q="'"//trim(spellings(i))//"'"
        source='program p'//nl//'character(8)::s,a(1)'//nl// &
            's=('//q//')'//nl//'a=[character(8)::'//q//']'//nl// &
            'if(s/='//q//')error stop 1'//nl// &
            'if(a(1)/='//q//')error stop 2'//nl// &
            'if(len('//q//')/='//digits(len_trim(spellings(i)))//')error stop 3'//nl//'end program'
        call parse_subset(source,p,d)
        call okay('literal parser')
        n=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_unary.or.p%expressions(j)%kind==ex_user_call) &
                error stop 'quoted token changed into a defined/unary operation'
            if(p%expressions(j)%kind==ex_literal.and.p%expressions(j)%typ==ty_character)n=n+1
        end do
        if(n/=5)error stop 'quoted literal occurrence count differs'
        call verify_frontend(source,p,d)
        call okay('literal adapter')
        call execute_program(p,d)
        call okay('literal runtime')
        checks=checks+1
    end do
    do i=1,6
        select case(i)
        case(1);q="print *,len('a' ')'"
        case(2);q="print *, (1 ')'"
        case(3);q="print '(a)' ',' '['"
        case(4);q="print *, 'a' ',' 'b'"
        case(5);q="print *, 'a' '//' 'b'"
        case(6);q="print *, '+' 1"
        end select
        source='program p'//nl//q//nl//'end program'
        call parse_subset(source,p,d)
        if(d%code/=1)then
            print *,i
            error stop 'quoted grammar token was accepted'
        end if
        checks=checks+1
    end do
    print '(a,i0,a)','PASS: ',checks,' punctuation literal/data and malformed grammar checks'
contains
    function digits(n) result(s)
        integer,intent(in)::n
        character(:),allocatable::s
        character(12)::buffer
        write(buffer,'(i0)')n
        s=trim(buffer)
    end function
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0)then
            print *,label,': ',d%message
            error stop 'punctuation literal check failed'
        end if
    end subroutine
end program
