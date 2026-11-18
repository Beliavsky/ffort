! SPDX-License-Identifier: MIT
program test_optional_numeric_arrays
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    type(program_t)::p
    type(diagnostic_t)::d
    character(:),allocatable::source,decl
    integer::form,mutation,s,j,actual,checks
    checks=0
    do form=1,10
        select case(form)
        case(1);decl='integer,optional,intent(in)::x(:)'
        case(2);decl='integer(8),optional,intent(in)::x(:,:)'
        case(3);decl='real,optional,intent(in)::x(:)'
        case(4);decl='real(8),optional,intent(in)::x(:,:)'
        case(5);decl='logical,optional,intent(in)::x(:)'
        case(6);decl='logical,optional,intent(in)::x(:,:)'
        case(7);decl='integer,allocatable,optional,intent(in)::x(:)'
        case(8);decl='integer(8),allocatable,optional,intent(in)::x(:,:)'
        case(9);decl='real,allocatable,optional,intent(in)::x(:)'
        case(10);decl='real(8),allocatable,optional,intent(in)::x(:,:)'
        end select
        source='program main'//nl//'call work()'//nl//'contains'//nl// &
            'subroutine work(x)'//nl//decl//nl// &
            'if(present(x)) error stop 1'//nl//'end subroutine'//nl//'end program'
        do mutation=1,11
            call parse_subset(source,p,d)
            call require(d%code==0,'declaration fixture parse')
            s=p%procedures(1)%args(1)
            select case(mutation)
            case(2);p%symbols(s)%is_optional=.false.
            case(3);p%symbols(s)%is_dummy=.false.
            case(4);p%symbols(s)%rank=4
            case(5);p%symbols(s)%typ=ty_derived_base
            case(6);p%symbols(s)%real_kind=16
            case(7);p%symbols(s)%assumed_shape=.not.p%symbols(s)%assumed_shape
            case(8);p%symbols(s)%deferred_character=.true.
            case(9);p%symbols(s)%character_len=12
            case(10);p%symbols(s)%is_automatic=.true.
            case(11);p%symbols(s)%scope=p%np+1
            end select
            call verify_frontend(source,p,d)
            call require((d%code==0).eqv.(mutation==1),'declaration adapter')
            d=diagnostic_t()
            call execute_program(p,d)
            call require((d%code==0).eqv.(mutation==1),'declaration runtime')
            if(mutation/=1)checks=checks+2
        end do
    end do
    do form=1,6
        select case(form)
        case(1);decl='integer(8),optional,intent(in)::x(:)'
        case(2);decl='real(8),optional,intent(in)::x(:,:)'
        case(3);decl='logical,optional,intent(in)::x(:)'
        case(4);decl='integer(8),allocatable,optional,intent(in)::x(:)'
        case(5);decl='real(8),allocatable,optional,intent(in)::x(:,:)'
        case(6);decl='logical,optional,intent(in)::x(:,:)'
        end select
        source='program main'//nl//'call outer()'//nl//'contains'//nl// &
            'subroutine outer(x)'//nl//decl//nl//'call inner(x)'//nl//'end subroutine'//nl// &
            'subroutine inner(x)'//nl//decl//nl//'if(present(x)) error stop 1'//nl// &
            'end subroutine'//nl//'end program'
        do mutation=1,9
            call parse_subset(source,p,d)
            call require(d%code==0,'forward fixture parse')
            actual=0
            do j=1,p%nc
                if(p%code(j)%op/=op_call)cycle
                if(.not.allocated(p%code(j)%items))cycle
                if(size(p%code(j)%items)/=1)cycle
                if(p%code(j)%items(1)>0)actual=p%code(j)%items(1)
            end do
            call require(actual>0,'forward fixture actual')
            select case(mutation)
            case(2);p%expressions(actual)%scope=42
            case(3);p%expressions(actual)%extent=-2_int64
            case(4);p%expressions(actual)%extent=int(max_array_elements,int64)+1_int64
            case(5);p%expressions(actual)%rank=3
            case(6);p%expressions(actual)%real_kind=16
            case(7);p%expressions(actual)%typ=ty_character
            case(8);p%expressions(actual)%extent=0_int64;p%expressions(actual)%dims=0_int64
            case(9)
                p%expressions(actual)%rank=2
                p%expressions(actual)%dims=[-2_int64,-1_int64,1_int64]
            end select
            call execute_program(p,d)
            call require((d%code==0).eqv.(mutation==1),'missing-actual descriptor')
            if(mutation/=1)checks=checks+1
        end do
    end do
    ! Supplied LOGICAL actuals must not lose corrupt kind metadata when the
    ! call frame copies values. Cover both whole variables and expressions.
    do form=1,2
        source='program main'//nl//'logical::a(2)'//nl//'a=.true.'//nl
        if(form==1)then
            source=source//'call work(a)'//nl
        else
            source=source//'call work(.not.a)'//nl
        end if
        source=source//'contains'//nl//'subroutine work(x)'//nl// &
            'logical,optional,intent(in)::x(:)'//nl// &
            'if(.not.present(x)) error stop 1'//nl//'end subroutine'//nl//'end program'
        do mutation=1,2
            call parse_subset(source,p,d)
            call require(d%code==0,'supplied logical kind fixture')
            actual=0
            do j=1,p%nc
                if(p%code(j)%op==op_call)actual=p%code(j)%items(1)
            end do
            call require(actual>0,'supplied logical kind actual')
            if(mutation==2)p%expressions(actual)%real_kind=8
            call execute_program(p,d)
            call require((d%code==0).eqv.(mutation==1),'supplied logical kind runtime')
            if(mutation/=1)checks=checks+1
        end do
    end do
    print *, 'PASS: OPTIONAL numeric/logical array descriptor mutations:',checks
contains
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' form=',form,' mutation=',mutation
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
