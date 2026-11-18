! SPDX-License-Identifier: MIT
program test_automatic_arrays
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(value_t)::answer,args(1)
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'integer function work(n) result(answer)'//nl//'integer,intent(in)::n'//nl// &
        'integer::aa(0:n-1,2)'//nl//'aa=2'//nl//'answer=sum(aa)+size(aa,1)'//nl// &
        'end function'//nl//'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
        'integer::v'//nl//'v=work(3)'//nl//'end program'
    integer::s,n,root,j,checks,mode
    checks=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'source parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'source adapter')
    s=0;n=0
    do j=1,p%ns
        if(p%symbols(j)%name=='aa')s=j
        if(p%symbols(j)%name=='n')n=j
    end do
    call expect(s>0,'local symbol found')
    call expect(p%symbols(s)%is_automatic,'automatic flag')
    root=p%symbols(s)%upper_expr
    args(1)=value_t(tag=ty_integer,i=3_int64)
    call execute_program(p,d,procedure_index=1,argument_values=args,procedure_value=answer)
    call expect(d%code==0,'scalar dummy allocation')
    call expect(answer%i==15,'rank two allocation and values')
    args(1)%i=0
    call execute_program(p,d,procedure_index=1,argument_values=args,procedure_value=answer)
    call expect(d%code==0.and.answer%i==0,'zero size new frame')
    args(1)%i=2
    call execute_program(p,d,procedure_index=1,argument_values=args,procedure_value=answer)
    call expect(d%code==0.and.answer%i==10,'third independent frame')
    do mode=1,14
        q=p;d=diagnostic_t()
        select case(mode)
        case(1);q%symbols(s)%is_automatic=.false.
        case(2);q%symbols(s)%is_parameter=.true.
        case(3);q%symbols(s)%is_dummy=.true.
        case(4);q%symbols(s)%assumed_shape=.true.
        case(5);q%symbols(s)%initializer_expr=root
        case(6);q%symbols(s)%rank=0
        case(7);q%symbols(s)%upper_expr=0
        case(8);q%symbols(s)%upper_expr=p%ne+1
        case(9);q%expressions(root)%typ=ty_real
        case(10);q%expressions(root)%rank=1
        case(11);q%expressions(root)%left=root
        case(12);q%symbols(n)%dummy_intent=2
        case(13);q%symbols(n)%is_optional=.true.
        case(14);q%symbols(s)%upper_bound2=3
        end select
        call verify_frontend(source,q,d)
        call expect(d%code/=0,'adapter rejects corruption')
        ! The adapter proves static cache/source agreement. The runtime checks
        ! the executable automatic-bound contract, even without the adapter.
        if(mode==14.or.mode==1)cycle
        d=diagnostic_t()
        call execute_program(q,d,procedure_index=1,argument_values=args,procedure_value=answer)
        call expect(d%code==2,'runtime rejects corruption')
    end do
    d=diagnostic_t()
    call execute_program(p,d,max_steps=1_int64,procedure_index=1,argument_values=args,procedure_value=answer)
    call expect(d%code==2,'bounds consume shared execution budget')
    print *, 'PASS: automatic array allocation and malformed IR checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' case ',mode
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
