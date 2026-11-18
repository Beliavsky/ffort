! SPDX-License-Identifier: MIT
! Independent composed adapter mutations and parser-free public-IR checks.
program test_release036_composition
    use,intrinsic::iso_fortran_env,only:int64,real64,output_unit,error_unit
    use,intrinsic::ieee_arithmetic,only:ieee_is_negative
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer(8)::a(3,2),b(3,2)'//nl//'real(8)::x(0)'//nl// &
        'a=reshape([-4_8,0_8,3_8,2_8,-1_8,7_8],[3,2])'//nl// &
        'b=dim(a([3,1,3],:),0_8)'//nl// &
        'if(sum(b)/=22_8)error stop 1'//nl// &
        'if(.not.parity(b>0_8))error stop 2'//nl// &
        'if(.not.parity(parity(b>0_8,dim=1)))error stop 3'//nl// &
        'if(sign(3d0,-0d0)/=-3d0)error stop 4'//nl// &
        'if(abs(log_gamma(3d0)-log(2d0))>1d-14)error stop 5'//nl// &
        'if(epsilon(x)/=2d0**(-52))error stop 6'//nl// &
        'if(radix(x)/=2)error stop 7'//nl// &
        'if(tiny(x)<=0d0)error stop 8'//nl// &
        'if(huge(0_8)/=9223372036854775807_8)error stop 9'//nl// &
        'write(*,''("composed:",3(1x,i0))'')sum(b),count(b>0_8),kind(tiny(x))'//nl// &
        'end program'
    character(9),parameter::names(8)=[character(9)::'dim','sign','log_gamma','parity','epsilon','radix','tiny','huge']
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(value_t)::v
    integer::checks,j,k,e,g,which,stage,status,family
    character(100)::line
    checks=0;which=0;stage=0;family=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d);call expect(d%code==0,'composition parse')
    call verify_frontend(source,p,d);call expect(d%code==0,'composition adapter')
    do j=1,3
        d=diagnostic_t();call clear_output();call execute_program(p,d)
        call expect(d%code==0,'repeat composition runtime')
        rewind(output_unit);read(output_unit,'(a)',iostat=status)line
        call expect(status==0.and.trim(line)=='composed: 22 5 8','independent exact record')
        read(output_unit,'(a)',iostat=status)line
        call expect(status<0,'single completed record')
    end do
    do family=1,8
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op==trim(names(family)).and.e==0)e=j
        end do
        call expect(e>0,'composed intrinsic retained')
        do which=1,8
            q=p
            select case(which)
            case(1);q%expressions(e)%real_kind=16
            case(2);q%expressions(e)%typ=ty_character
            case(3);q%expressions(e)%args(1)=0
            case(4);q%expressions(e)%args(1)=q%ne+1
            case(5);q%expressions(e)%args(1)=e
            case(6);q%expressions(e)%intrinsic_mask=-1
            case(7);q%expressions(e)%args=[integer::]
            case(8);q%expressions(e)%rank=4
            end select
            call reject_both(q,'composed intrinsic mutation')
        end do
    end do
    g=0
    do j=1,p%ne
        if(p%expressions(j)%kind==ex_gather_rows)g=j
    end do
    call expect(g>0,'gather inside DIM retained')
    do which=1,8
        q=p
        select case(which)
        case(1);q%expressions(g)%rank=1
        case(2);q%expressions(g)%left=g
        case(3);q%expressions(g)%typ=ty_logical
        case(4);q%expressions(g)%symbol=0
        case(5);q%expressions(g)%triplet(2)=.false.
        case(6);q%expressions(g)%intrinsic_mask=1
        case(7);q%expressions(g)%right=1
        case(8);q%expressions(g)%real_kind=4
        end select
        call reject_both(q,'gather composed with elemental/reduction mutation')
    end do
    ! These graphs are built directly, not parsed or adapter-certified.
    do which=0,10
        call direct_graph()
        select case(which)
        case(1);q%expressions(4)%real_kind=4
        case(2);q%expressions(4)%args=[1]
        case(3);q%expressions(4)%args(1)=4
        case(4);q%expressions(5)%args(2)=0
        case(5);q%expressions(5)%typ=ty_real
        case(6);q%expressions(5)%extent=1
        case(7);q%expressions(5)%rank=1
        case(8);q%expressions(1)%value%real_kind=4
        case(9);q%expressions(2)%typ=ty_real
        case(10);q%expressions(5)%intrinsic_mask=1
        end select
        call evaluate_constant(q,5,v,d)
        call expect((d%code==0).eqv.(which==0),'parser-free DIM(SIGN()) guard')
        if(which==0)call expect(v%i==4_int64.and.v%real_kind==8,'integer8 composed value')
    end do
    ! Model inquiries suppress an otherwise invalid LOG_GAMMA pole, but not metadata checks.
    do family=1,4
        do which=0,5
            call direct_model(family)
            select case(which)
            case(1);q%expressions(2)%real_kind=16
            case(2);q%expressions(2)%args=[integer::]
            case(3);q%expressions(2)%args=[2]
            case(4);q%expressions(3)%dims(1)=1_int64
            case(5);q%expressions(3)%intrinsic_mask=-1
            end select
            call evaluate_constant(q,3,v,d)
            call expect((d%code==0).eqv.(which==0),'parser-free model(LOG_GAMMA()) guard')
            if(which==0)then
                select case(family)
                case(1);call expect(v%r==2.0_real64**(-52),'binary64 epsilon exact')
                case(2);call expect(v%i==2_int64.and.v%real_kind==4,'radix exact')
                case(3);call expect(v%r==2.0_real64**(-1022),'binary64 tiny exact nonzero')
                case(4);call expect(v%r==(2d0-2d0**(-52))*2d0**1023,'binary64 huge exact')
                end select
            end if
        end do
    end do
    ! Direct REAL64 SIGN verifies the sign bit rather than approximate numeric equality.
    call direct_model(1)
    q%expressions(1)%value%r=0d0
    q%expressions(2)=expr_t(kind=ex_literal,typ=ty_real,real_kind=8, &
        value=value_t(tag=ty_real,real_kind=8,r=-0d0))
    q%expressions(3)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,op='sign',args=[1,2])
    call evaluate_constant(q,3,v,d)
    call expect(d%code==0.and.v%r==0d0,'parser-free zero sign value')
    call expect(ieee_is_negative(v%r),'negative zero bit retained')
    ! Direct PARITY graph over a logical constructor; never parser-certified.
    do which=0,6
        q=program_t();d=diagnostic_t()
        allocate(q%symbols(0),q%expressions(5),q%code(0));q%ne=5
        q%expressions(1)=expr_t(kind=ex_literal,typ=ty_logical,value=value_t(tag=ty_logical,l=.true.))
        q%expressions(2)=expr_t(kind=ex_literal,typ=ty_logical,value=value_t(tag=ty_logical,l=.false.))
        q%expressions(3)=expr_t(kind=ex_constructor,typ=ty_logical,rank=1,extent=3_int64, &
            args=[1,2,1])
        q%expressions(4)=expr_t(kind=ex_call,typ=ty_logical,op='parity',intrinsic_mask=1,args=[3])
        q%expressions(5)=expr_t(kind=ex_call,typ=ty_integer,op='kind',args=[4])
        select case(which)
        case(1);q%expressions(3)%real_kind=8
        case(2);q%expressions(4)%intrinsic_mask=7
        case(3);q%expressions(4)%args=[4]
        case(4);q%expressions(3)%rank=3
        case(5);q%expressions(4)%rank=1
        case(6);q%expressions(4)%args=[integer::]
        end select
        call evaluate_constant(q,4,v,d)
        call expect((d%code==0).eqv.(which==0),'parser-free PARITY guard')
        if(which==0)call expect(v%tag==ty_logical.and..not.v%l,'even parity exact')
        d=diagnostic_t();call evaluate_constant(q,5,v,d)
        call expect((d%code==0).eqv.(which==0),'KIND cannot conceal malformed PARITY')
    end do
    close(output_unit)
    write(error_unit,'(a,i0,a)')'PASS: release 0.36 independent composition: ',checks,' checks'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)label,' family=',family,' mutation=',which,' stage=',stage,' code=',d%code
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
    subroutine clear_output()
        rewind(output_unit);endfile(output_unit);rewind(output_unit)
    end subroutine
    subroutine reject_both(program,label)
        type(program_t),intent(in)::program
        character(*),intent(in)::label
        do stage=1,2
            d=diagnostic_t();call clear_output()
            if(stage==1)then
                call verify_frontend(source,program,d)
            else
                call execute_program(program,d,max_steps=10000_int64)
            end if
            call expect(d%code==stage,label)
            call expect(d%stop_status==0,'guard is not user STOP')
            call expect(allocated(d%message),'guard diagnostic exists')
            if(allocated(d%message))call expect(len_trim(d%message)>0,'guard diagnostic nonempty')
            rewind(output_unit);read(output_unit,'(a)',iostat=status)line
            call expect(status<0,'no partial output from corrupted composition')
        end do
    end subroutine
    subroutine direct_graph()
        q=program_t();d=diagnostic_t()
        allocate(q%symbols(0),q%expressions(5),q%code(0));q%ne=5
        q%expressions(1)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
            value=value_t(tag=ty_integer,real_kind=8,i=5_int64))
        q%expressions(2)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
            value=value_t(tag=ty_integer,real_kind=8,i=-3_int64))
        q%expressions(3)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
            value=value_t(tag=ty_integer,real_kind=8,i=-9_int64))
        q%expressions(4)=expr_t(kind=ex_call,typ=ty_integer,real_kind=8,op='sign',args=[1,2])
        q%expressions(5)=expr_t(kind=ex_call,typ=ty_integer,real_kind=8,op='dim',args=[4,3])
    end subroutine
    subroutine direct_model(n)
        integer,intent(in)::n
        q=program_t();d=diagnostic_t()
        allocate(q%symbols(0),q%expressions(3),q%code(0));q%ne=3
        q%expressions(1)=expr_t(kind=ex_literal,typ=ty_real,real_kind=8, &
            value=value_t(tag=ty_real,real_kind=8,r=0d0))
        q%expressions(2)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,op='log_gamma',args=[1])
        q%expressions(3)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,op=trim(names(n+4)),args=[2])
        if(n==2)then
            q%expressions(3)%typ=ty_integer;q%expressions(3)%real_kind=4
        end if
    end subroutine
end program
