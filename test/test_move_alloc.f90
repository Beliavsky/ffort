! SPDX-License-Identifier: MIT
program test_move_alloc
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser, only:parse_subset
    use fi_frontend, only:verify_frontend
    use fi_runtime, only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a'),source='program p'//nl//'integer,allocatable::a(:),b(:)'//nl// &
        'allocate(a(-1:1),b(1))'//nl//'a=[4,5,6]'//nl//'b=99'//nl// &
        'call move_alloc(a,b)'//nl//'if(allocated(a).or.size(b)/=3) error stop 1'//nl// &
        'if(any(b/=[4,5,6]).or.lbound(b,1)/=-1) error stop 2'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::j,pc,which,checks
    checks=0;which=0;pc=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'baseline producer/adapter')
    do j=1,p%nc
        if(p%code(j)%op==op_move_alloc)pc=j
    end do
    call expect(pc>0,'MOVE_ALLOC opcode')
    call expect(valid_move_alloc(p,p%code(pc)),'public baseline descriptor')
    do j=1,3
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'fresh repeated ownership and lifetime')
    end do
    do which=1,113
        q=p
        select case(which)
        case(1);q%code(pc)%op=op_allocate
        case(2);q%code(pc)%scope=1
        case(3);q%code(pc)%symbol=1
        case(4);q%code(pc)%a=1
        case(5);q%code(pc)%b=1
        case(6);q%code(pc)%c=1
        case(7);q%code(pc)%d=1
        case(8);q%code(pc)%third=1
        case(9);q%code(pc)%target=1
        case(10);q%code(pc)%component=1
        case(11);q%code(pc)%generic_id=1
        case(12);q%code(pc)%bound_type=1
        case(13);q%code(pc)%bound_binding=1
        case(14);q%code(pc)%construct_name='x'
        case(15);q%code(pc)%format='(a)'
        case(16);q%code(pc)%format_expr=1
        case(17);q%code(pc)%advance_mode=1
        case(18);q%code(pc)%items=[0,0]
        case(19);q%code(pc)%items=[p%ne+1,p%ne+1]
        case(20);q%code(pc)%items=[p%code(pc)%items(1)]
        case(21);q%code(pc)%items=[p%code(pc)%items(1),p%code(pc)%items(1)]
        case(22);q%expressions(p%code(pc)%items(1))%kind=ex_call
        case(23);q%expressions(p%code(pc)%items(1))%scope=1
        case(24);q%expressions(p%code(pc)%items(1))%typ=ty_real
        case(25);q%expressions(p%code(pc)%items(1))%real_kind=8
        case(26);q%expressions(p%code(pc)%items(1))%rank=0
        case(27);q%expressions(p%code(pc)%items(1))%extent=0_int64
        case(28);q%expressions(p%code(pc)%items(1))%dims=1_int64
        case(29);q%expressions(p%code(pc)%items(1))%character_len=3
        case(30);q%expressions(p%code(pc)%items(1))%parenthesized=.true.
        case(31);q%expressions(p%code(pc)%items(1))%symbol=0
        case(32);q%expressions(p%code(pc)%items(1))%symbol=p%ns+1
        case(33);q%expressions(p%code(pc)%items(1))%left=1
        case(34);q%expressions(p%code(pc)%items(1))%right=1
        case(35);q%expressions(p%code(pc)%items(1))%stride=1
        case(36);q%expressions(p%code(pc)%items(1))%left2=1
        case(37);q%expressions(p%code(pc)%items(1))%right2=1
        case(38);q%expressions(p%code(pc)%items(1))%stride2=1
        case(39);q%expressions(p%code(pc)%items(1))%left3=1
        case(40);q%expressions(p%code(pc)%items(1))%right3=1
        case(41);q%expressions(p%code(pc)%items(1))%stride3=1
        case(42);q%expressions(p%code(pc)%items(1))%third=1
        case(43);q%expressions(p%code(pc)%items(1))%length_expr=1
        case(44);q%expressions(p%code(pc)%items(1))%generic_id=1
        case(45);q%expressions(p%code(pc)%items(1))%bound_type=1
        case(46);q%expressions(p%code(pc)%items(1))%bound_binding=1
        case(47);q%expressions(p%code(pc)%items(1))%intrinsic_mask=1
        case(48);q%expressions(p%code(pc)%items(1))%constructor_kind_expr=1
        case(49);q%expressions(p%code(pc)%items(1))%constructor_owner=1
        case(50);q%expressions(p%code(pc)%items(1))%op='bad'
        case(51);q%expressions(p%code(pc)%items(1))%args=[1]
        case(52);q%expressions(p%code(pc)%items(1))%triplet=.false.
        case(53);q%expressions(p%code(pc)%items(1))%value%tag=ty_integer
        case(54);q%expressions(p%code(pc)%items(1))%value%i=1_int64
        case(55);q%expressions(p%code(pc)%items(1))%value%r=1.0
        case(56);q%expressions(p%code(pc)%items(1))%value%l=.true.
        case(57);q%expressions(p%code(pc)%items(1))%value%real_kind=8
        case(58);q%expressions(p%code(pc)%items(1))%value%s='bad'
        case(59);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%is_allocatable=.false.
        case(60);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%is_pointer=.true.
        case(61);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%is_parameter=.true.
        case(62);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%dummy_intent=1
        case(63);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%is_class=.true.
        case(64);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%is_intrinsic=.true.
        case(65);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%rank=4
        case(66);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%typ=ty_real
        case(67);q%symbols(p%expressions(p%code(pc)%items(1))%symbol)%real_kind=8
        case(68);q%expressions(p%code(pc)%items(2))%kind=ex_call
        case(69);q%expressions(p%code(pc)%items(2))%scope=1
        case(70);q%expressions(p%code(pc)%items(2))%typ=ty_real
        case(71);q%expressions(p%code(pc)%items(2))%real_kind=8
        case(72);q%expressions(p%code(pc)%items(2))%rank=0
        case(73);q%expressions(p%code(pc)%items(2))%extent=0_int64
        case(74);q%expressions(p%code(pc)%items(2))%dims=1_int64
        case(75);q%expressions(p%code(pc)%items(2))%character_len=3
        case(76);q%expressions(p%code(pc)%items(2))%parenthesized=.true.
        case(77);q%expressions(p%code(pc)%items(2))%symbol=0
        case(78);q%expressions(p%code(pc)%items(2))%symbol=p%ns+1
        case(79);q%expressions(p%code(pc)%items(2))%left=1
        case(80);q%expressions(p%code(pc)%items(2))%right=1
        case(81);q%expressions(p%code(pc)%items(2))%stride=1
        case(82);q%expressions(p%code(pc)%items(2))%left2=1
        case(83);q%expressions(p%code(pc)%items(2))%right2=1
        case(84);q%expressions(p%code(pc)%items(2))%stride2=1
        case(85);q%expressions(p%code(pc)%items(2))%left3=1
        case(86);q%expressions(p%code(pc)%items(2))%right3=1
        case(87);q%expressions(p%code(pc)%items(2))%stride3=1
        case(88);q%expressions(p%code(pc)%items(2))%third=1
        case(89);q%expressions(p%code(pc)%items(2))%length_expr=1
        case(90);q%expressions(p%code(pc)%items(2))%generic_id=1
        case(91);q%expressions(p%code(pc)%items(2))%bound_type=1
        case(92);q%expressions(p%code(pc)%items(2))%bound_binding=1
        case(93);q%expressions(p%code(pc)%items(2))%intrinsic_mask=1
        case(94);q%expressions(p%code(pc)%items(2))%constructor_kind_expr=1
        case(95);q%expressions(p%code(pc)%items(2))%constructor_owner=1
        case(96);q%expressions(p%code(pc)%items(2))%op='bad'
        case(97);q%expressions(p%code(pc)%items(2))%args=[1]
        case(98);q%expressions(p%code(pc)%items(2))%triplet=.false.
        case(99);q%expressions(p%code(pc)%items(2))%value%tag=ty_integer
        case(100);q%expressions(p%code(pc)%items(2))%value%i=1_int64
        case(101);q%expressions(p%code(pc)%items(2))%value%r=1.0
        case(102);q%expressions(p%code(pc)%items(2))%value%l=.true.
        case(103);q%expressions(p%code(pc)%items(2))%value%real_kind=8
        case(104);q%expressions(p%code(pc)%items(2))%value%s='bad'
        case(105);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%is_allocatable=.false.
        case(106);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%is_pointer=.true.
        case(107);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%is_parameter=.true.
        case(108);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%dummy_intent=1
        case(109);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%is_class=.true.
        case(110);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%is_intrinsic=.true.
        case(111);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%rank=4
        case(112);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%typ=ty_real
        case(113);q%symbols(p%expressions(p%code(pc)%items(2))%symbol)%real_kind=8
        end select
        call expect(.not.valid_move_alloc(q,q%code(pc)),'public malformed descriptor')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code/=0,'adapter rejects mutation')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code/=0,'runtime rejects mutation')
    end do
    print '(a,i0,a)','PASS: ',checks,' MOVE_ALLOC checks'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(.not.ok)then
            print *, 'FAIL: ',trim(label), ' mutation ',which
            if(allocated(d%message))print *,d%message
            error stop 1
        end if
    end subroutine
end program
