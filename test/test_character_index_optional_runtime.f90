! SPDX-License-Identifier: MIT
program test_character_index_optional_runtime
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'contains'//nl// &
        'integer function pos(b) result(v)'//nl//'logical,optional,intent(in)::b'//nl// &
        "v=index('aba','a',back=b)"//nl//'end function'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'if(pos()/=1)error stop 1'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::mutation,j,e,a,s
    do mutation=0,9
        call parse_subset(source,p,d)
        if(d%code/=0)error stop 'INDEX absent baseline parse'
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op=='index')e=j
        end do
        if(e==0)error stop 'INDEX absent call missing'
        a=p%expressions(e)%args(3);s=p%expressions(a)%symbol
        select case(mutation)
        case(1);p%expressions(a)%scope=0
        case(2);p%expressions(a)%extent=1
        case(3);p%expressions(a)%dims=[1_int64,0_int64,1_int64]
        case(4);p%expressions(a)%typ=ty_integer
        case(5);p%expressions(a)%real_kind=8
        case(6);p%expressions(a)%rank=1
        case(7);p%symbols(s)%typ=ty_integer
        case(8);p%symbols(s)%real_kind=8
        case(9);p%expressions(a)%parenthesized=.true.
        end select
        call execute_program(p,d)
        if((d%code==0).neqv.(mutation==0)) then
            print *, 'INDEX absent mutation ',mutation,' code ',d%code
            if(allocated(d%message))print *,d%message
            error stop 'INDEX absent metadata validation'
        end if
    end do
    print *, 'PASS: INDEX absent BACK baseline and nine malformed-descriptor rejections'
end program
