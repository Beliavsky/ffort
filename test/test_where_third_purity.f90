! SPDX-License-Identifier: MIT
! Exercise WHERE's independent direct-IR purity guard, including third-axis selectors.
program test_where_third_purity
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,assignment,result_value
    integer::which,e,root,proc,slot
    do which=1,7
        result_value='1';slot=1
        select case(which)
        case(1)
            assignment='where(b==0) b=a(1,1,pick())';slot=0
        case(2)
            assignment='where(b==0) b=a(:,:,pick())'
        case(3)
            assignment='where(b==0) b=a(1,:,pick():2)'
        case(4)
            assignment='where(b==0) b=a(1,:,1:pick())';slot=2;result_value='2'
        case(5)
            assignment='where(b==0) b=a(1,:,1:2:pick())';slot=3
        case(6)
            assignment='where(b==0) a(1,:,pick():2)=7'
        case(7)
            assignment='where(a(:,:,pick())==4) b=7'
        end select
        source='program p'//nl//'integer::a(2,2,2),b(2,2)'//nl// &
            'a=4'//nl//'b=0'//nl//assignment//nl//'contains'//nl// &
            'pure integer function pick()'//nl//'pick='//result_value//nl// &
            'end function'//nl//'end program'
        call parse_subset(source,p,d)
        call require(d%code==0,'baseline parse',which)
        root=0
        do e=1,p%ne
            if(p%expressions(e)%kind/=ex_element.and.p%expressions(e)%kind/=ex_section) cycle
            select case(slot)
            case(0);root=p%expressions(e)%third
            case(1);root=p%expressions(e)%left3
            case(2);root=p%expressions(e)%right3
            case(3);root=p%expressions(e)%stride3
            end select
            if(root<=0) cycle
            if(p%expressions(root)%kind==ex_user_call) exit
            root=0
        end do
        call require(root>0,'third-axis call retained',which)
        proc=p%expressions(root)%symbol
        call execute_program(p,d)
        call require(d%code==0,'pure baseline executes',which)
        ! Bypass source and adapter guards exactly as a public IR caller can.
        p%procedures(proc)%is_pure=.false.
        call execute_program(p,d)
        call require(d%code==2,'impure selector rejected',which)
        call require(allocated(d%message),'purity diagnostic present',which)
        call require(index(d%message,'WHERE expressions require PURE functions')>0, &
                     'WHERE traversal supplies rejection',which)
    end do
    print '(a)','PASS: seven WHERE third-axis scalar/triplet purity baseline/mutation pairs'
contains
    subroutine require(ok,what,which)
        logical,intent(in)::ok
        character(*),intent(in)::what
        integer,intent(in)::which
        if(ok) return
        print *,trim(what),which,d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
