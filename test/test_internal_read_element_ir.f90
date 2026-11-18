! SPDX-License-Identifier: MIT
! Unbuilt native IR/parser mutation draft for central integrated verification.
program test_internal_read_element_ir
    use, intrinsic :: iso_fortran_env, only: int64,error_unit
    use, intrinsic :: ieee_arithmetic, only: ieee_value,ieee_quiet_nan
    use fi_ir
    use fi_parser, only: parse_subset
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(4)::a(-1:1)'//nl//'integer::i,ios,n'//nl// &
        'i=0'//nl//'a(0)="3"'//nl//'read(a(i+0),*,iostat=ios)n'//nl//'end program'
    type(program_t)::p,q,saved
    type(diagnostic_t)::d
    type(expr_t),allocatable::grown(:)
    integer::base,root,param_symbol,read_pc
    integer::checks,pc,j,target,s,index_root,leaf,ss,which,output_symbol
    checks=0;which=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parser')
    pc=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_internal)pc=j
    end do
    call expect(pc>0,'internal instruction')
    target=p%code(pc)%a;s=p%expressions(target)%symbol
    index_root=p%expressions(target)%left;leaf=p%expressions(index_root)%left
    ss=p%expressions(p%code(pc)%b)%symbol;output_symbol=p%expressions(p%code(pc)%items(1))%symbol
    call expect(valid_internal_read(p,p%code(pc)),'baseline full gate')
    saved=p
    do which=1,97
        q=saved
        select case(which)
        case(1);q%expressions(target)%kind=ex_variable
        case(2);q%expressions(target)%symbol=0
        case(3);q%expressions(target)%symbol=q%ns+1
        case(4);q%expressions(target)%rank=1
        case(5);q%expressions(target)%typ=ty_integer
        case(6);q%expressions(target)%real_kind=8
        case(7);q%expressions(target)%character_len=3
        case(8);q%expressions(target)%extent=1_int64
        case(9);q%expressions(target)%dims(1)=1_int64
        case(10);q%expressions(target)%parenthesized=.true.
        case(11);q%expressions(target)%left=0
        case(12);q%expressions(target)%left=q%ne+1
        case(13);q%expressions(target)%right=index_root
        case(14);q%expressions(target)%third=index_root
        case(15);q%expressions(target)%stride=index_root
        case(16);q%expressions(target)%left2=index_root
        case(17);q%expressions(target)%right2=index_root
        case(18);q%expressions(target)%stride2=index_root
        case(19);q%expressions(target)%left3=index_root
        case(20);q%expressions(target)%right3=index_root
        case(21);q%expressions(target)%stride3=index_root
        case(22);q%expressions(target)%length_expr=index_root
        case(23);q%expressions(target)%constructor_owner=1
        case(24);q%expressions(target)%constructor_kind_expr=index_root
        case(25);q%expressions(target)%generic_id=1
        case(26);q%expressions(target)%bound_type=1
        case(27);q%expressions(target)%bound_binding=1
        case(28);q%expressions(target)%intrinsic_mask=1
        case(29);q%expressions(target)%op='forged'
        case(30);q%expressions(target)%args=[index_root]
        case(31);q%expressions(target)%triplet(1)=.false.
        case(32);q%expressions(target)%value%tag=ty_character
        case(33);q%expressions(target)%value%s='forged'
        case(34);q%symbols(s)%is_pointer=.true.
        case(35);q%symbols(s)%is_parameter=.true.
        case(36);q%symbols(s)%dummy_intent=1
        case(37);q%symbols(s)%is_class=.true.
        case(38);q%symbols(s)%is_intrinsic=.true.
        case(39);q%symbols(s)%scope=1
        case(40);q%symbols(s)%rank=0
        case(41);q%expressions(index_root)%rank=1
        case(42);q%expressions(index_root)%typ=ty_real
        case(43);q%expressions(index_root)%real_kind=2
        case(44);q%expressions(index_root)%extent=1_int64
        case(45);q%expressions(index_root)%dims(1)=1_int64
        case(46);q%expressions(leaf)%scope=1
        case(47);q%expressions(leaf)%constructor_owner=1
        case(48);q%expressions(leaf)%kind=ex_user_call
        case(49);q%expressions(leaf)%kind=ex_component
        case(50);q%expressions(leaf)%kind=ex_output_do
        case(51);q%expressions(index_root)%left=index_root
        case(52);q%expressions(leaf)%symbol=ss
        case(53);q%code(pc)%format='(a4)'
        case(54);q%expressions(leaf)%symbol=output_symbol
        case(55);q%code(pc)%scope=-1
        case(56);q%expressions(leaf)%dims(1)=1_int64
        case(57);q%expressions(leaf)%real_kind=8
        case(58);q%expressions(leaf)%rank=1;q%expressions(leaf)%extent=1_int64
        case(59);q%expressions(leaf)%typ=ty_real
        case(60);q%expressions(leaf)%extent=1_int64
        case(61);q%expressions(q%expressions(index_root)%right)%value%real_kind=8
        case(62);q%expressions(q%expressions(index_root)%right)%value%s='hidden'
        case(63);allocate(q%expressions(q%expressions(index_root)%right)%value%record)
        case(64);q%expressions(leaf)%value%s='hidden'
        case(65);allocate(q%expressions(leaf)%value%record)
        case(66);q%expressions(index_root)%length_expr=leaf
        case(67);q%expressions(index_root)%constructor_kind_expr=leaf
        case(68);q%expressions(q%expressions(index_root)%right)%value%l=.true.
        case(69);q%expressions(q%expressions(index_root)%right)%value%i=2147483648_int64
        case(70);q%expressions(leaf)%character_len=0
        case(71);q%expressions(index_root)%value%tag=ty_integer
        case(72);q%expressions(q%expressions(index_root)%right)%rank=1
        case(73);q%expressions(q%expressions(index_root)%right)%value%r=1.0
        case(74);q%symbols(s)%is_dummy=.true.
        case(75);q%symbols(s)%is_saved=.true.
        case(76);q%symbols(s)%is_optional=.true.
        case(77);q%symbols(s)%is_automatic=.true.
        case(78);q%symbols(s)%assumed_shape=.true.
        case(79);q%symbols(s)%deferred_character=.true.
        case(80);q%symbols(s)%length_expr=leaf
        case(81);q%expressions(index_root)%generic_id=1
        case(82);q%expressions(index_root)%real_kind=8
        case(83);q%expressions(index_root)%op='forged'
        case(84);q%expressions(leaf)%left=leaf
        case(85);q%expressions(leaf)%kind=ex_call
        case(86);q%symbols(s)%character_len=5;q%expressions(target)%character_len=5
        case(87);q%symbols(s)%lower_bound=-2_int64
        case(88);q%symbols(s)%upper_bound=2_int64
        case(89);q%symbols(s)%length_expr=0
        case(90);q%symbols(s)%upper_expr=0
        case(91);q%symbols(s)%lower_expr=0
        case(92);q%symbols(s)%lower_expr2=leaf
        case(93);q%expressions(q%symbols(s)%length_expr)%value%tag=ty_real
        case(94);q%expressions(q%symbols(s)%length_expr)%value%real_kind=8
        case(95);q%expressions(q%symbols(s)%length_expr)%value%s='hidden'
        case(96);q%expressions(q%symbols(s)%length_expr)%value%i=2147483648_int64
        case(97);q%expressions(q%symbols(s)%lower_expr)%left=q%symbols(s)%lower_expr
        end select
        call expect(.not.valid_internal_read(q,q%code(pc)),'mutation full gate rejects')
    end do
    ! A compact acyclic shared DAG must be linear-time, not exponentially
    ! reevaluated. Every subtraction node shares both edges with its predecessor.
    q=saved;base=q%ne
    allocate(grown(base+62));grown(:base)=q%expressions(:base)
    grown(base+1)=expr_t();grown(base+1)%kind=ex_literal;grown(base+1)%typ=ty_integer
    grown(base+1)%value%tag=ty_integer
    do j=2,61
        grown(base+j)=expr_t();grown(base+j)%kind=ex_binary;grown(base+j)%typ=ty_integer
        grown(base+j)%op='-';grown(base+j)%left=base+j-1;grown(base+j)%right=base+j-1
    end do
    root=base+62;grown(root)=expr_t();grown(root)%kind=ex_binary;grown(root)%typ=ty_integer
    grown(root)%op='+';grown(root)%left=base+61;grown(root)%right=q%symbols(s)%length_expr
    call move_alloc(grown,q%expressions);q%ne=root;q%symbols(s)%length_expr=root
    call expect(valid_internal_read(q,q%code(pc)),'shared declaration DAG accepted with memoized value')
    q%expressions(base+61)%left=base+61
    call expect(.not.valid_internal_read(q,q%code(pc)),'shared declaration DAG cycle rejected')
    call parse_subset('program p'//nl//'implicit none'//nl//'integer,parameter::k=int(4.5)'//nl// &
        'character(k)::a(1)'//nl//'integer::i,n'//nl//'i=1'//nl//'read(a(i),*)n'//nl//'end program',q,d)
    call expect(d%code==0,'converted integer parameter declaration parser')
    param_symbol=0;read_pc=0
    do j=1,q%ns
        if(q%symbols(j)%name=='k')param_symbol=j
    end do
    do j=1,q%nc
        if(q%code(j)%op==op_read_internal)read_pc=j
    end do
    call expect(param_symbol>0.and.read_pc>0,'parameter fixture identities')
    call expect(valid_internal_read(q,q%code(read_pc)),'finite inactive converted parameter real cache accepted')
    q%symbols(param_symbol)%constant_value%r=ieee_value(0.0d0,ieee_quiet_nan)
    call expect(.not.valid_internal_read(q,q%code(read_pc)),'nonfinite inactive parameter cache rejected')
    write(*,'(a,i0)')'internal READ element IR checks: ',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(.not.ok)then
            write(error_unit,'(a,i0,2a)')'FAIL mutation ',which,': ',label
            stop 1
        end if
    end subroutine
end program
