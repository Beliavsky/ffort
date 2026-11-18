! SPDX-License-Identifier: MIT
! Independently authored composition tests: no implementation helper is an oracle.
program test_release038_composition
    use,intrinsic::iso_fortran_env,only:int64,real32,real64,output_unit,error_unit
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant,evaluate_constant_array,evaluate_constant_shape
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl// &
        'use,intrinsic::iso_fortran_env,only:dp=>real64,ik=>int64'//nl// &
        'implicit none'//nl//'real(dp),target::a(3)'//nl//'real(dp),pointer::p(:),q(:)'//nl// &
        'real(dp)::b(3)'//nl//'integer(ik)::s'//nl//'p=>a'//nl//'q=>a(3:1:-1)'//nl// &
        'if(.not.associated(p,a))error stop 1'//nl//'if(associated(p,q))error stop 2'//nl// &
        'a=[0._dp,1._dp,2._dp]'//nl//'s=1_ik'//nl//'b=cshift(erfc_scaled(a),s)'//nl// &
        'if(abs(b(1)-0.4275835761558070044_dp)>4e-16_dp)error stop 3'//nl// &
        'if(b(3)/=1._dp)error stop 4'//nl//'write(*,''(a)'')''ok'''//nl//'end program'
    character(11),parameter::families(3)=[character(11)::'erfc_scaled','cshift','associated']
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(value_t)::v
    type(value_t),allocatable::values(:)
    integer::checks,family,mutation,stage,e,k,j,root,import_index,ios
    integer(int64)::dims(3)
    real(real64)::least,expected(4)
    character(100)::line
    character(:),allocatable::actual
    checks=0;family=0;mutation=0;stage=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d);call expect(d%code==0,'valid composition parses')
    call verify_frontend(source,p,d);call expect(d%code==0,'valid composition adapter')
    do j=1,2
        d=diagnostic_t();call clear_output();call execute_program(p,d)
        call expect(d%code==0,'valid composition execution')
        call read_output(actual);call expect(actual=='ok'//nl,'exact valid composed output')
    end do
    do family=1,3
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op==trim(families(family)).and.e==0)e=j
        end do
        call expect(e>0,'intrinsic has real composed occurrence')
        do mutation=1,11
            q=p
            select case(mutation)
            case(1);q%expressions(e)%typ=ty_character
            case(2);q%expressions(e)%real_kind=16
            case(3);q%expressions(e)%args(1)=0
            case(4);q%expressions(e)%args(1)=e
            case(5);q%expressions(e)%args(1)=q%ne+1
            case(6);q%expressions(e)%intrinsic_mask=-1
            case(7);q%expressions(e)%rank=4
            case(8);q%expressions(e)%dims(3)=17_int64
            case(9);q%expressions(e)%args=[integer::]
            case(10);deallocate(q%expressions(e)%args)
            case(11);q%expressions(q%expressions(e)%args(1))%real_kind=16
            end select
            call reject_both('composed intrinsic malformed descriptor')
            k=q%ne+1;q%ne=k
            q%expressions(k)=expr_t(kind=ex_call,typ=ty_integer,op='kind',args=[e])
            d=diagnostic_t();call evaluate_constant(q,k,v,d)
            call expect(d%code/=0,'KIND cannot hide malformed composition')
        end do
    end do
    ! Same numerical kind value is not the same imported remote identity.
    import_index=0
    do j=1,p%ns
        if(p%symbols(j)%name=='dp')import_index=j
    end do
    call expect(import_index>0,'aliased import found')
    q=p;q%symbols(import_index)%intrinsic_import='int64'
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'adapter preserves exact imported remote identity')
    ! Standalone IR may legitimately call the same-value import INT64. This is
    ! not malformed at runtime: only source/adapter identity was inconsistent.
    d=diagnostic_t();call clear_output();call execute_program(q,d)
    call expect(d%code==0,'valid changed remote identity remains standalone IR')
    call read_output(actual);call expect(actual=='ok'//nl,'standalone same-kind result')
    do mutation=1,5
        q=p
        select case(mutation)
        case(1);q%symbols(import_index)%intrinsic_import='missing'
        case(2);q%symbols(import_index)%constant_value%i=16
        case(3);q%symbols(import_index)%is_pointer=.true.
        case(4);q%symbols(import_index)%is_parameter=.false.
        case(5);q%symbols(import_index)%rank=1
        end select
        call reject_both('forged alias descriptor')
    end do
    ! Parser-free graphs: CSHIFT(ERFC_SCALED([0,1,2]),INT64_MIN), plus
    ! KIND/SHAPE roots. Every independent valid baseline runs before its mutant.
    do mutation=0,14
        call direct_graph()
        select case(mutation)
        case(1);q%expressions(5)%intrinsic_mask=1
        case(2);q%expressions(5)%real_kind=4
        case(3);q%expressions(5)%args(1)=5
        case(4);q%expressions(5)%rank=2
        case(5);q%expressions(7)%intrinsic_mask=7
        case(6);q%expressions(7)%extent=2
        case(7);q%expressions(7)%dims=[3_int64,1_int64,0_int64]
        case(8);q%expressions(7)%args=[5]
        case(9);q%expressions(7)%args(2)=0
        case(10);q%expressions(6)%real_kind=16
        case(11);q%expressions(6)%typ=ty_real
        case(12);q%expressions(2)%value%real_kind=16
        case(13);q%expressions(4)%extent=2
        case(14);q%expressions(7)%rank=3
        end select
        d=diagnostic_t();call evaluate_constant_array(q,7,values,d)
        call expect((d%code==0).eqv.(mutation==0),'parser-free nested array validation')
        if(mutation==0)then
            call expect(size(values)==3,'exact parser-free shape')
            call expect(abs(values(1)%r-0.4275835761558070044d0)<=4*spacing(0.4275835761558070044d0), &
                'independent ERFC value in shifted first element')
            call expect(abs(values(2)%r-0.25539567631050574387d0)<=4*spacing(0.25539567631050574387d0), &
                'independent ERFC value in shifted second element')
            call expect(values(3)%r==1d0,'exact shifted zero-argument result')
        end if
        d=diagnostic_t();call evaluate_constant(q,8,v,d)
        call expect((d%code==0).eqv.(mutation==0),'parser-free KIND validates descendants')
        if(mutation==0)call expect(v%i==8,'parser-free KIND exact')
        d=diagnostic_t();call evaluate_constant_shape(q,7,dims,d)
        call expect((d%code==0).eqv.(mutation==0),'parser-free descriptor validation')
        if(mutation==0)call expect(all(dims==[3_int64,1_int64,1_int64]),'parser-free shape exact')
    end do
    ! CSHIFT is a pure permutation, including exact subnormal values and signed
    ! zero bits. Do not use any ERFC tolerance or a generic numeric comparator.
    do family=1,2
        q=program_t();allocate(q%symbols(0),q%code(0),q%expressions(7));q%ne=7
        least=tiny(0d0)*epsilon(0d0)
        if(family==1)least=real(tiny(0.0_real32)*epsilon(0.0_real32),real64)
        expected=[0d0,least,-least,-0d0]
        do j=1,4
            q%expressions(j)=expr_t(kind=ex_literal,typ=ty_real,real_kind=4*family, &
                value=value_t(tag=ty_real,real_kind=4*family))
        end do
        q%expressions(1)%value%r=-0d0;q%expressions(2)%value%r=0d0
        q%expressions(3)%value%r=least;q%expressions(4)%value%r=-least
        q%expressions(5)=expr_t(kind=ex_constructor,typ=ty_real,real_kind=4*family,rank=1,extent=4_int64, &
            args=[1,2,3,4])
        q%expressions(6)=expr_t(kind=ex_literal,typ=ty_integer, &
            value=value_t(tag=ty_integer,i=1_int64))
        q%expressions(7)=expr_t(kind=ex_call,op='cshift',typ=ty_real,real_kind=4*family,rank=1,extent=4_int64, &
            args=[5,6],intrinsic_mask=3)
        d=diagnostic_t();call evaluate_constant_array(q,7,values,d)
        call expect(d%code==0,'signed-zero/subnormal permutation baseline')
        call expect(size(values)==4,'signed-zero/subnormal exact shape')
        do j=1,4
            call expect(transfer(values(j)%r,0_int64)==transfer(expected(j),0_int64), &
                'CSHIFT preserves exact promoted IEEE bits')
        end do
        call expect(values(2)%r/=0d0.and.values(3)%r/=0d0,'CSHIFT cannot replace tiny values with zero')
    end do
    ! Scalar source-free independent extreme references. These are rounded
    ! 120-digit mathematical values, never GNU endpoint results.
    do family=1,2
        do mutation=1,2
            q=program_t();allocate(q%symbols(0),q%code(0),q%expressions(2));q%ne=2
            q%expressions(1)=expr_t(kind=ex_literal,typ=ty_real,real_kind=4*family, &
                value=value_t(tag=ty_real,real_kind=4*family))
            q%expressions(2)=expr_t(kind=ex_call,typ=ty_real,real_kind=4*family,op='erfc_scaled',args=[1])
            if(family==1)then
                if(mutation==1)q%expressions(1)%value%r=real(huge(0.0_real32),real64)
                if(mutation==2)q%expressions(1)%value%r=-9.3824138641357421875d0
            else
                if(mutation==1)q%expressions(1)%value%r=huge(0d0)
                if(mutation==2)q%expressions(1)%value%r=-26.628735713751489d0
            end if
            d=diagnostic_t();call evaluate_constant(q,2,v,d)
            call expect(d%code==0,'extreme finite endpoint executes')
            call expect(v%r>0d0,'extreme positive result cannot become zero')
            if(mutation==1)then
                if(family==1)call expect(v%r<real(tiny(0.0_real32),real64),'REAL4 tail is subnormal')
                if(family==2)call expect(v%r<tiny(0d0),'REAL8 tail is subnormal')
            else
                if(family==1)q%expressions(1)%value%r=real(nearest(real(q%expressions(1)%value%r,real32), &
                    -1.0_real32),real64)
                if(family==2)q%expressions(1)%value%r=nearest(q%expressions(1)%value%r,-1d0)
                d=diagnostic_t();call evaluate_constant(q,2,v,d)
                call expect(d%code/=0,'next representable negative neighbor rejects')
                call expect(index(d%message,'finite result range')>0,'endpoint rejection is finite policy')
            end if
        end do
    end do
    write(error_unit,'(a,i0)')'PASS: release038 independent native assertions: ',checks
contains
    subroutine direct_graph()
        integer::i
        q=program_t();allocate(q%symbols(0),q%code(0),q%expressions(8));q%ne=8
        do i=1,3
            q%expressions(i)=expr_t(kind=ex_literal,typ=ty_real,real_kind=8, &
                value=value_t(tag=ty_real,real_kind=8,r=real(i-1,real64)))
        end do
        q%expressions(4)=expr_t(kind=ex_constructor,typ=ty_real,real_kind=8,rank=1,extent=3_int64, &
            args=[1,2,3])
        q%expressions(5)=expr_t(kind=ex_call,op='erfc_scaled',typ=ty_real,real_kind=8,rank=1,extent=3_int64, &
            args=[4])
        q%expressions(6)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
            value=value_t(tag=ty_integer,real_kind=8,i=-huge(0_int64)-1_int64))
        q%expressions(7)=expr_t(kind=ex_call,op='cshift',typ=ty_real,real_kind=8,rank=1,extent=3_int64, &
            args=[5,6],intrinsic_mask=3)
        q%expressions(8)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[7])
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
            call expect(d%stop_status==0,'metadata guard is not user STOP')
            call expect(allocated(d%message),'diagnostic exists')
            call read_output(actual);call expect(actual=='','malformed graph emits no stdout')
        end do
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)'FAIL ',family,mutation,stage,trim(label)
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 'release038 native failure'
    end subroutine
end program
