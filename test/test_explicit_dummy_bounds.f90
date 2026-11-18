! SPDX-License-Identifier: MIT
program test_explicit_dummy_bounds
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'integer::a(3,2,2)'//nl//'call work(a,2)'//nl//'contains'//nl// &
        'subroutine work(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'integer,intent(out)::x(0:n-1,2,2)'//nl// &
        'x=7'//nl//'if(size(x)/=8) error stop 1'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::which,j,xsym,nsym,root,checks
    checks=0
    do which=1,24
        call parse_subset(source,p,d)
        call expect(d%code==0,'fixture parser')
        xsym=0;nsym=0
        do j=1,p%ns
            if(p%symbols(j)%name=='x')xsym=j
            if(p%symbols(j)%name=='n')nsym=j
        end do
        root=p%symbols(xsym)%upper_expr
        select case(which)
        case(2);p%symbols(xsym)%is_automatic=.false.
        case(3);p%symbols(xsym)%is_parameter=.true.
        case(4);p%symbols(xsym)%is_allocatable=.true.
        case(5);p%symbols(xsym)%is_optional=.true.
        case(6);p%symbols(xsym)%initializer_expr=root
        case(7);p%symbols(xsym)%upper_expr=0
        case(8);p%symbols(xsym)%upper_expr=p%ne+1
        case(9);p%expressions(root)%typ=ty_real
        case(10);p%expressions(root)%rank=1
        case(11);p%expressions(root)%left=root
        case(12);p%symbols(nsym)%dummy_intent=2
        case(13);p%symbols(nsym)%is_optional=.true.
        case(14);p%symbols(xsym)%upper_bound2=3
        case(15);p%symbols(xsym)%lower_bound2=0
        case(16);p%symbols(xsym)%upper_expr2=0
        case(17);p%symbols(xsym)%upper_expr3=0
        case(18);p%expressions(root)%scope=999
        case(19);p%symbols(xsym)%scope=999
        case(20);p%symbols(nsym)%is_dummy=.false.
        case(21);p%expressions(p%expressions(root)%left)%symbol=p%ns+1
        case(22);p%symbols(xsym)%is_dummy=.false.
        case(23);p%symbols(xsym)%upper_bound3=0
        case(24);p%symbols(xsym)%assumed_shape=.true.
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'adapter')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==1),'runtime')
        if(which/=1)checks=checks+2
    end do
    print *, 'PASS: explicit-shape dummy independent mutations:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
