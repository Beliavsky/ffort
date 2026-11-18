! SPDX-License-Identifier: MIT
program test_findloc
    use, intrinsic :: iso_fortran_env, only:int64
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
    integer::family,mutation,e,j,checks,array,value_arg,mask_arg,kind_arg,back_arg
    checks=0
    do family=1,4
        select case(family)
        case(1);call_text='findloc([3,1,1],1,mask=[.true.,.true.,.true.],kind=8,back=.true.)'
        case(2);call_text='findloc(reshape([2,9,9,1],[2,2]),9,mask=.true.,kind=8,back=.true.)'
        case(3);call_text='findloc(["a ","bb","a "],"a",mask=.true.,kind=8,back=.true.)'
        case(4);call_text='findloc([.true.,.false.,.true.],.true.,1,mask=.true.,kind=8,back=.true.)'
        end select
        source='program p'//nl//'print *,'//call_text//nl//'end program'
        do mutation=0,20
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
            if(mutation==0) then
                select case(family)
                case(1,3)
                    call expect(size(values)==1.and.values(1)%i==3.and.values(1)%real_kind==8,'last matching element')
                case(2)
                    call expect(size(values)==2.and.all(values%i==[1_int64,2_int64]),'matrix last match')
                case(4)
                    call expect(value%i==3.and.value%real_kind==8,'logical scalar DIM result')
                end select
            end if
        end do
    end do
    source='program p'//nl//'integer::a(2),v,d'//nl//'logical::m(2),back'//nl// &
        'print *,kind(findloc(a,v,dim=d,mask=m,back=back,kind=8))'//nl//'end program'
    call fixture()
    do j=1,p%ne
        if(p%expressions(j)%op=='kind') exit
    end do
    call evaluate_constant(p,j,value,d)
    call expect(d%code==0,'KIND does not read data')
    call expect(value%i==8,'KIND result')
    p%expressions(value_arg)%rank=1
    call evaluate_constant(p,j,value,d)
    call expect(d%code/=0,'KIND still checks FINDLOC VALUE rank')
    print '(a,i0,a)','PASS: FINDLOC values, KIND inquiry and ',checks,' adapter/runtime checks'
contains
    subroutine fixture()
        integer::i,slot,k
        call parse_subset(source,p,d)
        call expect(d%code==0,'fixture parse')
        e=0
        do i=1,p%ne
            if(p%expressions(i)%kind==ex_call.and.p%expressions(i)%op=='findloc') e=i
        end do
        call expect(e>0,'FINDLOC expression exists')
        array=p%expressions(e)%args(1);value_arg=p%expressions(e)%args(2)
        k=0;mask_arg=0;kind_arg=0;back_arg=0
        do slot=1,6
            if(.not.btest(p%expressions(e)%intrinsic_mask,slot-1)) cycle
            k=k+1
            select case(slot)
            case(4);mask_arg=p%expressions(e)%args(k)
            case(5);kind_arg=p%expressions(e)%args(k)
            case(6);back_arg=p%expressions(e)%args(k)
            end select
        end do
    end subroutine
    subroutine mutate()
        select case(mutation)
        case(1);deallocate(p%expressions(e)%args)
        case(2);p%expressions(e)%args(1)=0
        case(3);p%expressions(e)%intrinsic_mask=ibclr(p%expressions(e)%intrinsic_mask,1)
        case(4);p%expressions(e)%rank=2
        case(5);p%expressions(e)%typ=ty_logical
        case(6);p%expressions(e)%real_kind=16
        case(7);p%expressions(e)%character_len=0
        case(8);p%expressions(e)%extent=99_int64
        case(9);p%expressions(e)%dims(1)=1_int64
        case(10);p%expressions(array)%rank=0
        case(11);p%expressions(value_arg)%rank=1
        case(12);p%expressions(value_arg)%typ=ty_derived_base
        case(13);p%expressions(kind_arg)%value%i=4_int64
        case(14);p%expressions(mask_arg)%typ=ty_integer
        case(15);p%expressions(back_arg)%rank=1
        case(16);p%expressions(array)%rank=3
        case(17);p%expressions(e)%args(2)=e
        case(18);p%expressions(value_arg)%real_kind=16
        case(19);p%expressions(e)%intrinsic_mask=64
        case(20);p%expressions(array)%real_kind=16
        end select
    end subroutine
    subroutine expect(ok,what)
        logical,intent(in)::ok
        character(*),intent(in)::what
        checks=checks+1
        if(ok) return
        print *,what,' family=',family,' mutation=',mutation,' status=',d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
