! SPDX-License-Identifier: MIT
program test_location_intrinsics
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:evaluate_constant_array,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t),allocatable::values(:)
    type(value_t)::value
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,call_text
    integer::family,mutation,e,j,checks,kind_expr,selector
    checks=0
    do family=1,4
        select case(family)
        case(1);call_text='minloc([3,1,1],mask=[.true.,.true.,.true.],kind=8,back=.true.)'
        case(2);call_text='maxloc(reshape([2,9,9,1],[2,2]))'
        case(3);call_text='minloc(reshape([2,9,9,1],[2,2]),1,mask=.false.)'
        case(4);call_text='maxloc([3,1,3],1,back=.true.)'
        end select
        source='program p'//nl//'implicit none'//nl//'print *,'//call_text//nl//'end program'
        do mutation=0,17
            call fixture()
            call mutate()
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter metadata mutation')
            d=diagnostic_t()
            if(family==4) then
                call evaluate_constant(p,e,value,d)
            else
                call evaluate_constant_array(p,e,values,d)
            end if
            call expect((d%code==0).eqv.(mutation==0),'runtime metadata mutation')
            if(mutation==0)then
                select case(family)
                case(1)
                    call expect(size(values)==1.and.values(1)%i==3.and.values(1)%real_kind==8,'last minimum')
                case(2)
                    call expect(size(values)==2,'matrix result size')
                    call expect(all(values%i==[2_int64,1_int64]),'matrix first maximum')
                case(3)
                    call expect(size(values)==2,'DIM result size')
                    call expect(all(values%i==0),'MASK false locations')
                case(4)
                    call expect(value%i==3,'scalar DIM result')
                end select
            end if
        end do
    end do
    source='program p'//nl//'implicit none'//nl//'integer(8)::a(2,2)'//nl// &
        'logical::mask(2,2),back'//nl//'integer::dim'//nl// &
        'print *,kind(minloc(a,dim=dim,mask=mask,back=back,kind=8))'//nl//'end program'
    do mutation=0,4
        call fixture()
        select case(mutation)
        case(1);p%expressions(e)%rank=2
        case(2);p%expressions(e)%typ=ty_character
        case(3);p%expressions(e)%real_kind=4
        case(4);p%expressions(e)%intrinsic_mask=0
        end select
        kind_expr=0
        do j=1,p%ne
            if(p%expressions(j)%op=='kind')kind_expr=j
        end do
        d=diagnostic_t()
        call evaluate_constant(p,kind_expr,value,d)
        call expect((d%code==0).eqv.(mutation==0),'unevaluated KIND validates MINLOC')
        if(mutation==0)call expect(value%i==8,'KIND does not evaluate ARRAY/DIM/MASK/BACK')
    end do
    source='program p'//nl//'implicit none'//nl//'integer(8)::a(2)'//nl// &
        'print *,kind(minloc(a,kind=4+4))'//nl//'end program'
    do mutation=0,4
        call fixture()
        selector=p%expressions(e)%args(2)
        select case(mutation)
        case(1);p%expressions(e)%real_kind=4
        case(2);p%expressions(selector)%left=selector
        case(3);p%expressions(selector)%op='*'
        case(4)
            p%expressions(selector)%kind=ex_variable
            p%expressions(selector)%symbol=p%expressions(p%expressions(e)%args(1))%symbol
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'compound KIND selector adapter')
        kind_expr=0
        do j=1,p%ne
            if(p%expressions(j)%op=='kind')kind_expr=j
        end do
        d=diagnostic_t()
        call evaluate_constant(p,kind_expr,value,d)
        call expect((d%code==0).eqv.(mutation==0),'compound KIND selector runtime')
        if(mutation==0)call expect(value%i==8,'compound KIND selector value')
    end do
    print *, 'PASS: MINLOC/MAXLOC adapter/runtime checks:',checks
contains
    subroutine fixture()
        call parse_subset(source,p,d)
        call expect(d%code==0,'fixture parses')
        e=0
        do j=1,p%ne
            if(is_location_reduction(p%expressions(j)%op))e=j
        end do
        call expect(e>0,'location intrinsic exists')
    end subroutine
    subroutine mutate()
        select case(mutation)
        case(1);p%expressions(e)%typ=ty_real
        case(2);p%expressions(e)%real_kind=16
        case(3);p%expressions(e)%rank=2
        case(4);p%expressions(e)%extent=500
        case(5);p%expressions(e)%dims=[1_int64,1_int64,1_int64]
        case(6);p%expressions(e)%args(1)=0
        case(7);p%expressions(e)%args(1)=p%ne+1
        case(8);p%expressions(e)%args=[integer::]
        case(9);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
        case(10);p%expressions(e)%intrinsic_mask=0
        case(11);p%expressions(e)%intrinsic_mask=32
        case(12);p%expressions(e)%intrinsic_mask=ibclr(p%expressions(e)%intrinsic_mask,0)
        case(13);p%expressions(p%expressions(e)%args(1))%typ=ty_logical
        case(14);p%expressions(p%expressions(e)%args(1))%rank=0
        case(15);p%expressions(e)%character_len=17
        case(16);p%expressions(p%expressions(e)%args(1))%real_kind=16
        case(17);deallocate(p%expressions(e)%args)
        end select
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' family ',family,' mutation ',mutation
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
