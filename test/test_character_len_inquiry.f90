! SPDX-License-Identifier: MIT
program test_character_len_inquiry
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,decl,body
    type(program_t)::p
    type(diagnostic_t)::d
    integer::mode,which,j,e,a,checks,failures
    checks=0;failures=0
    do mode=1,5
        select case(mode)
        case(1);decl='character(7)::s';body='if(s%len/=7) error stop 1'
        case(2);decl='character(7)::s';body='if(kind(s%len)/=4) error stop 1'
        case(3);decl='character(7)::s(2,0)';body='if(s%len/=7) error stop 1'
        case(4);decl='character(:),allocatable::s(:,:)';body='if(kind(s%len)/=4) error stop 1'
        case(5);decl='character(7)::s'//nl//'integer::z(0)';body='z=s%len+z'
        end select
        source='program p'//nl//'implicit none'//nl//decl//nl//body//nl//'end program'
        do which=0,63
            d=diagnostic_t();call parse_subset(source,p,d)
            if(d%code/=0)error stop 'LEN native baseline parse failed'
            e=0
            do j=1,p%ne
                if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op=='len')e=j
            end do
            if(e==0)error stop 'LEN native call missing'
            a=p%expressions(e)%args(1)
            select case(which)
            case(1);deallocate(p%expressions(e)%args)
            case(2);p%expressions(e)%args=[integer::]
            case(3);p%expressions(e)%args=[a,a]
            case(4);p%expressions(e)%args=[0]
            case(5);p%expressions(e)%args=[p%ne+1]
            case(6);p%expressions(e)%args=[e]
            case(7);p%expressions(e)%typ=ty_real
            case(8);p%expressions(e)%real_kind=8
            case(9);p%expressions(e)%rank=1
            case(10);p%expressions(e)%extent=1
            case(11);p%expressions(e)%dims=[1_int64,0_int64,0_int64]
            case(12);p%expressions(e)%symbol=1
            case(13);p%expressions(e)%left=1
            case(14);p%expressions(e)%right=1
            case(15);p%expressions(e)%stride=1
            case(16);p%expressions(e)%left2=1
            case(17);p%expressions(e)%right2=1
            case(18);p%expressions(e)%stride2=1
            case(19);p%expressions(e)%left3=1
            case(20);p%expressions(e)%right3=1
            case(21);p%expressions(e)%stride3=1
            case(22);p%expressions(e)%third=1
            case(23);p%expressions(e)%length_expr=1
            case(24);p%expressions(e)%generic_id=1
            case(25);p%expressions(e)%bound_type=1
            case(26);p%expressions(e)%bound_binding=1
            case(27);p%expressions(e)%intrinsic_mask=1
            case(28);p%expressions(e)%constructor_kind_expr=1
            case(29);p%expressions(e)%scope=1
            case(30);p%expressions(e)%character_len=7
            case(31);p%expressions(e)%triplet(1)=.false.
            case(32);p%expressions(e)%triplet(2)=.true.
            case(33);p%expressions(e)%triplet(3)=.true.
            case(34);p%expressions(a)%typ=ty_integer
            case(35);p%expressions(a)%real_kind=8
            case(36);p%expressions(a)%rank=3
            case(37);p%expressions(a)%character_len=9
            case(38);p%expressions(a)%extent=-2
            case(39);p%expressions(a)%dims=[9_int64,0_int64,0_int64]
            case(40);allocate(p%expressions(a)%args(0))
            case(41);p%expressions(a)%op='bad'
            case(42);p%expressions(a)%symbol=0
            case(43);p%expressions(a)%symbol=p%ns+1
            case(44);p%expressions(a)%left=1
            case(45);p%expressions(a)%right=1
            case(46);p%expressions(a)%stride=1
            case(47);p%expressions(a)%left2=1
            case(48);p%expressions(a)%right2=1
            case(49);p%expressions(a)%stride2=1
            case(50);p%expressions(a)%left3=1
            case(51);p%expressions(a)%right3=1
            case(52);p%expressions(a)%stride3=1
            case(53);p%expressions(a)%third=1
            case(54);p%expressions(a)%length_expr=1
            case(55);p%expressions(a)%generic_id=1
            case(56);p%expressions(a)%bound_type=1
            case(57);p%expressions(a)%bound_binding=1
            case(58);p%expressions(a)%intrinsic_mask=1
            case(59);p%expressions(a)%constructor_kind_expr=1
            case(60);p%expressions(a)%scope=1
            case(61);p%expressions(a)%triplet(1)=.false.
            case(62);p%expressions(a)%triplet(2)=.true.
            case(63);p%expressions(a)%triplet(3)=.true.
            end select
            call verify_frontend(source,p,d)
            call check('adapter')
            d=diagnostic_t();call execute_program(p,d)
            call check('runtime')
        end do
    end do
    if(failures/=0)error stop 'LEN malformed metadata accepted'
    print '(a,i0,a)','CHARACTER %LEN: ',checks,' native checks passed'
contains
    subroutine check(stage)
        character(*),intent(in)::stage
        integer::expected
        expected=0
        if(which/=0)expected=merge(1,2,stage=='adapter')
        checks=checks+1
        if(d%code/=expected)then
            failures=failures+1
            print *,stage,mode,which,d%code
            if(allocated(d%message))print *,d%message
        end if
    end subroutine
end program
