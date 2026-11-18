! SPDX-License-Identifier: MIT
program test_pack_intrinsic
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
    character(:),allocatable::source,pack_text
    integer::family,mutation,e,j,checks,kind_expr
    checks=0
    do family=1,3
        select case(family)
        case(1);pack_text='pack([1,2,3],[.true.,.false.,.true.],[9,8,7])'
        case(2);pack_text='pack([1,2,3],.false.)'
        case(3);pack_text="pack(['ab','cd','ef'],[.true.,.false.,.true.],['uv','wx','yz'])"
        end select
        source='program p'//nl//'implicit none'//nl//'print *,'//pack_text//nl//'end program'
        do mutation=0,16
            call fixture()
            call mutate()
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter metadata mutation')
            d=diagnostic_t()
            call evaluate_constant_array(p,e,values,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime metadata mutation')
            if(mutation==0)then
                select case(family)
                case(1)
                    call expect(size(values)==3,'integer result size')
                    call expect(all(values%i==[1_int64,3_int64,7_int64]),'integer result values')
                case(2)
                    call expect(size(values)==0,'empty PACK result')
                case(3)
                    call expect(size(values)==3,'character result size')
                    call expect(values(1)%s=='ab'.and.values(2)%s=='ef'.and.values(3)%s=='yz','character values')
                end select
            end if
        end do
    end do
    family=1
    source='program p'//nl//'implicit none'//nl//'integer(8)::a(2)'//nl//'logical::mask(2)'//nl// &
        'print *,kind(pack(a,mask))'//nl//'end program'
    do mutation=0,4
        call fixture()
        select case(mutation)
        case(1);p%expressions(e)%rank=2
        case(2);p%expressions(e)%typ=ty_character
        case(3);p%expressions(e)%real_kind=4
        case(4);p%expressions(e)%args=[p%expressions(e)%args(1)]
        end select
        kind_expr=0
        do j=1,p%ne
            if(p%expressions(j)%op=='kind')kind_expr=j
        end do
        d=diagnostic_t()
        call evaluate_constant(p,kind_expr,value,d)
        call expect((d%code==0).eqv.(mutation==0),'unevaluated KIND validates PACK')
        if(mutation==0)call expect(value%i==8,'KIND does not evaluate PACK MASK')
    end do
    print *, 'PASS: PACK adapter/runtime checks:',checks
contains
    subroutine fixture()
        call parse_subset(source,p,d)
        call expect(d%code==0,'fixture parses')
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op=='pack')e=j
        end do
        call expect(e>0,'PACK exists')
    end subroutine
    subroutine mutate()
        select case(mutation)
        case(1);p%expressions(e)%typ=ty_real
        case(2);p%expressions(e)%real_kind=8
        case(3);p%expressions(e)%rank=2
        case(4);p%expressions(e)%rank=0
        case(5);p%expressions(e)%extent=0
        case(6);p%expressions(e)%dims=[1_int64,1_int64,1_int64]
        case(7);p%expressions(e)%args(1)=0
        case(8);p%expressions(e)%args(2)=p%ne+1
        case(9);p%expressions(e)%args=[integer::]
        case(10);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
        case(11);p%expressions(e)%args=[p%expressions(e)%args(1)]
        case(12);p%expressions(p%expressions(e)%args(2))%typ=ty_integer
        case(13);p%expressions(p%expressions(e)%args(1))%rank=0
        case(14);p%expressions(e)%character_len=17
        case(15);p%expressions(p%expressions(e)%args(2))%real_kind=8
        case(16);deallocate(p%expressions(e)%args)
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
