! SPDX-License-Identifier: MIT
program test_allocatable_character
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl// &
        'character(:),allocatable::a(:)'//nl// &
        'allocate(character(3)::a(-1:0))'//nl// &
        'a="abcd"'//nl// &
        'if(len(a)/=3.or.a(-1)/="abc") error stop 1'//nl// &
        'a=[character(5)::"hello","world"]'//nl// &
        'if(len(a)/=5.or.lbound(a,1)/=1) error stop 2'//nl// &
        'deallocate(a)'//nl//'if(allocated(a)) error stop 3'//nl//'end program'
    integer::i,j,a,e,s
    do i=1,9
        call fresh()
        s=1;a=0
        do j=1,p%nc
            if(p%code(j)%op==op_allocate) a=j
        end do
        if(a==0) error stop 'missing allocation'
        e=p%code(a)%b
        select case(i)
        case(2);p%symbols(s)%deferred_character=.false.
        case(3);p%symbols(s)%character_len=3
        case(4);p%symbols(s)%length_expr=e
        case(5);p%code(a)%b=0
        case(6);p%expressions(e)%typ=ty_real
        case(7);p%expressions(e)%rank=1
        case(8);p%code(a)%b=p%ne+1
        case(9);p%symbols(s)%is_allocatable=.false.
        end select
        call verify_frontend(source,p,d)
        if(i==1) then
            call require_ok('verify')
        else if(d%code/=1) then
            print *,i,d%code
            error stop 'forged allocatable CHARACTER IR passed adapter'
        end if
        d=diagnostic_t()
        call execute_program(p,d)
        if(i==1) then
            call require_ok('run')
        else if(d%code/=2) then
            print *,i,d%code
            error stop 'corrupt allocatable CHARACTER IR passed runtime'
        end if
    end do
    print '(a)','PASS: allocatable CHARACTER descriptors and 16 adapter/runtime mutation rejections'
contains
    subroutine fresh()
        call parse_subset(source,p,d)
        call require_ok('parse')
    end subroutine
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected allocatable CHARACTER failure'
        end if
    end subroutine
end program
