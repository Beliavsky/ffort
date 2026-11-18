! SPDX-License-Identifier: MIT
! Independently authored combined public-IR guards, with no implementation oracle.
program test_release039_composition
    use,intrinsic::iso_fortran_env,only:int64,real64,output_unit,error_unit
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant,evaluate_constant_array,evaluate_constant_shape
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl// &
        'use,intrinsic::iso_fortran_env,only:dp=>real64,sp=>real32,ik=>int64'//nl// &
        'implicit none'//nl//'real(dp)::x(3),y(3),u'//nl//'real(sp)::z(3)'//nl// &
        'x=[0._dp,1._dp,0._dp]'//nl//'z=cshift(anint(erf(x),sp),1_ik)'//nl// &
        'if(any(z/=[1._sp,0._sp,0._sp]))error stop 1'//nl// &
        'y=aint(asinh(bessel_jn(1_ik,x)),dp)'//nl//'if(any(y/=0._dp))error stop 2'//nl// &
        'if(aint(acosh(1._dp))/=0._dp)error stop 3'//nl// &
        'if(bessel_j0(0._dp)/=1._dp.or.bessel_j1(0._dp)/=0._dp)error stop 4'//nl// &
        'if(minexponent(bessel_y0(u))/=-1021)error stop 5'//nl// &
        'if(maxexponent(bessel_y1(u))/=1024)error stop 6'//nl// &
        'if(kind(bessel_yn(99_ik,u))/=dp)error stop 7'//nl// &
        'write(*,''(a)'')''ok'''//nl//'end program'
    character(11),parameter::families(13)=[character(11)::'aint','anint','asinh','acosh','erf', &
        'bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn','minexponent','maxexponent']
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(value_t)::v
    type(value_t),allocatable::values(:)
    integer::checks,family,mutation,stage,e,k,j,ios
    integer(int64)::dims(3)
    character(100)::line
    character(:),allocatable::actual
    checks=0;family=0;mutation=0;stage=0
    close(output_unit);open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d);call expect(d%code==0,'combined baseline parses')
    call verify_frontend(source,p,d);call expect(d%code==0,'combined baseline adapter')
    d=diagnostic_t();call clear_output();call execute_program(p,d)
    call expect(d%code==0,'combined baseline executes');call read_output(actual)
    call expect(actual=='ok'//nl,'combined baseline exact stdout')
    do family=1,size(families)
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op==trim(families(family)).and.e==0)e=j
        end do
        call expect(e>0,'real composed family occurrence')
        do mutation=1,9
            q=p
            select case(mutation)
            case(1);q%expressions(e)%typ=ty_character
            case(2);q%expressions(e)%real_kind=16
            case(3);q%expressions(e)%args(1)=0
            case(4);q%expressions(e)%args(1)=e
            case(5);q%expressions(e)%args(1)=q%ne+1
            case(6);q%expressions(e)%intrinsic_mask=-1
            case(7);q%expressions(e)%rank=4
            case(8);q%expressions(e)%args=[integer::]
            case(9);deallocate(q%expressions(e)%args)
            end select
            call reject_both('malformed combined descriptor')
            k=q%ne+1;q%ne=k
            q%expressions(k)=expr_t(kind=ex_call,typ=ty_integer,op='kind',args=[e])
            d=diagnostic_t();call evaluate_constant(q,k,v,d)
            call expect(d%code/=0,'KIND must not hide invalid descendants')
        end do
    end do
    ! Parser-free pipeline: JN([0,1,2],0) -> AINT(...,REAL4) -> CSHIFT.
    ! All baseline values are exact integers, not GNU/host-math references.
    do mutation=0,13
        call direct_graph()
        select case(mutation)
        case(1);q%expressions(6)%intrinsic_mask=1
        case(2);q%expressions(6)%real_kind=4
        case(3);q%expressions(6)%args(1)=6
        case(4);q%expressions(6)%rank=2
        case(5);q%expressions(8)%real_kind=8
        case(6);q%expressions(7)%value%i=16
        case(7);q%expressions(8)%args(1)=10
        case(8);q%expressions(10)%extent=2
        case(9);q%expressions(10)%dims=[3_int64,1_int64,0_int64]
        case(10);q%expressions(10)%intrinsic_mask=7
        case(11);q%expressions(10)%args(2)=0
        case(12);q%expressions(1)%value%real_kind=16
        case(13);q%expressions(4)%extent=2
        end select
        d=diagnostic_t();call evaluate_constant_array(q,10,values,d)
        call expect((d%code==0).eqv.(mutation==0),'direct nested array validation')
        if(mutation==0)then
            call expect(size(values)==3,'direct array extent')
            call expect(all(values%r==[0d0,0d0,1d0]),'direct exact permutation')
            call expect(all(values%real_kind==4),'direct narrowed result kind')
        end if
        d=diagnostic_t();call evaluate_constant(q,11,v,d)
        call expect((d%code==0).eqv.(mutation==0),'model inquiry validates composed descendants')
        if(mutation==0)call expect(v%i==-125,'direct selected-kind MINEXPONENT')
        d=diagnostic_t();call evaluate_constant_shape(q,10,dims,d)
        call expect((d%code==0).eqv.(mutation==0),'direct descriptor validation')
        if(mutation==0)call expect(all(dims==[3_int64,1_int64,1_int64]),'direct shape exact')
    end do
    close(output_unit)
    write(error_unit,'(a,i0,a)')'release039 composition: ',checks,' assertions passed'
contains
    subroutine direct_graph()
        integer::i
        q=program_t();allocate(q%symbols(0),q%code(0),q%expressions(11));q%ne=11
        do i=1,3
            q%expressions(i)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
                value=value_t(tag=ty_integer,real_kind=8,i=int(i-1,int64)))
        end do
        q%expressions(4)=expr_t(kind=ex_constructor,typ=ty_integer,real_kind=8,rank=1,extent=3_int64, &
            args=[1,2,3])
        q%expressions(5)=expr_t(kind=ex_literal,typ=ty_real,real_kind=8,value=value_t(tag=ty_real,real_kind=8,r=0d0))
        q%expressions(6)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,rank=1,extent=3_int64, &
            op='bessel_jn',args=[4,5])
        q%expressions(7)=expr_t(kind=ex_literal,typ=ty_integer,value=value_t(tag=ty_integer,i=4_int64))
        q%expressions(8)=expr_t(kind=ex_call,typ=ty_real,real_kind=4,rank=1,extent=3_int64, &
            op='aint',args=[6,7])
        q%expressions(9)=expr_t(kind=ex_literal,typ=ty_integer,value=value_t(tag=ty_integer,i=1_int64))
        q%expressions(10)=expr_t(kind=ex_call,typ=ty_real,real_kind=4,rank=1,extent=3_int64, &
            op='cshift',args=[8,9],intrinsic_mask=3)
        q%expressions(11)=expr_t(kind=ex_call,typ=ty_integer,op='minexponent',args=[10])
    end subroutine
    subroutine clear_output()
        rewind(output_unit);endfile(output_unit);rewind(output_unit)
    end subroutine
    subroutine read_output(s)
        character(:),allocatable,intent(out)::s
        s='';rewind(output_unit)
        do
            read(output_unit,'(a)',iostat=ios)line
            if(ios/=0)exit
            s=s//trim(line)//nl
        end do
    end subroutine
    subroutine reject_both(label)
        character(*),intent(in)::label
        do stage=1,2
            d=diagnostic_t();call clear_output()
            if(stage==1)then
                call verify_frontend(source,q,d)
            else
                call execute_program(q,d,max_steps=10000_int64)
            end if
            call expect(d%code==stage,label)
            call expect(d%stop_status==0,'guard is not user STOP')
            call expect(allocated(d%message),'guard diagnostic exists')
            call read_output(actual);call expect(actual=='','invalid graph emits no stdout')
        end do
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)'FAIL ',family,mutation,stage,trim(label)
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 'release039 native failure'
    end subroutine
end program
