! SPDX-License-Identifier: MIT
program test_allocation_errmsg
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser, only:parse_subset
    use fi_frontend, only:verify_frontend
    use fi_runtime, only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a'),source='program p'//nl//'integer,allocatable::a(:),b(:)'//nl// &
        'integer::stat'//nl//'character(80)::msg'//nl// &
        'allocate(a(2),b(3),stat=stat,errmsg=msg)'//nl// &
        'if(stat/=0) error stop 1'//nl// &
        'deallocate(a,b,stat=stat,errmsg=msg)'//nl// &
        'deallocate(a,stat=stat,errmsg=msg)'//nl// &
        'if(stat==0.or.len_trim(msg)==0) error stop 2'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::j,pc,e,s,which,checks,k
    character(:),allocatable::uppercase_source
    checks=0;which=0;pc=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'baseline producer/adapter')
    do j=1,p%nc
        if(p%code(j)%op==op_allocate.and.pc==0)pc=j
    end do
    call expect(pc>0,'allocation opcode')
    e=p%code(pc)%third;s=p%expressions(e)%symbol
    call expect(valid_allocation_output(p,e,ty_character,0),'public message output')
    call expect(valid_allocation_message(p,p%code(pc)),'public controls')
    call expect(valid_allocation_group(p,pc),'public group')
    d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'baseline execution')
    uppercase_source=source
    do
        k=index(uppercase_source,'stat=')
        if(k==0)exit
        uppercase_source(k:k+3)='STAT'
    end do
    do
        k=index(uppercase_source,'errmsg=')
        if(k==0)exit
        uppercase_source(k:k+5)='ERRMSG'
    end do
    d=diagnostic_t();call parse_subset(uppercase_source,q,d)
    call expect(d%code==0,'uppercase option parser')
    call verify_frontend(uppercase_source,q,d)
    call expect(d%code==0,'uppercase independent producer and adapter')
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code==0,'uppercase option execution')
    do which=1,45
        q=p
        select case(which)
        case(1);q%expressions(e)%kind=ex_call
        case(2);q%expressions(e)%scope=1
        case(3);q%expressions(e)%typ=ty_real
        case(4);q%expressions(e)%real_kind=8
        case(5);q%expressions(e)%rank=1
        case(6);q%expressions(e)%extent=1_int64
        case(7);q%expressions(e)%dims=1_int64
        case(8);q%expressions(e)%character_len=3
        case(9);q%expressions(e)%parenthesized=.true.
        case(10);q%expressions(e)%symbol=0
        case(11);q%expressions(e)%symbol=p%ns+1
        case(12);q%expressions(e)%left=1
        case(13);q%expressions(e)%right=1
        case(14);q%expressions(e)%stride=1
        case(15);q%expressions(e)%left2=1
        case(16);q%expressions(e)%right2=1
        case(17);q%expressions(e)%stride2=1
        case(18);q%expressions(e)%left3=1
        case(19);q%expressions(e)%right3=1
        case(20);q%expressions(e)%stride3=1
        case(21);q%expressions(e)%third=1
        case(22);q%expressions(e)%length_expr=1
        case(23);q%expressions(e)%generic_id=1
        case(24);q%expressions(e)%bound_type=1
        case(25);q%expressions(e)%bound_binding=1
        case(26);q%expressions(e)%intrinsic_mask=1
        case(27);q%expressions(e)%constructor_kind_expr=1
        case(28);q%expressions(e)%constructor_owner=1
        case(29);q%expressions(e)%op='bad'
        case(30);q%expressions(e)%args=[1]
        case(31);q%expressions(e)%triplet=.false.
        case(32);q%expressions(e)%value%tag=ty_character
        case(33);q%expressions(e)%value%i=1_int64
        case(34);q%expressions(e)%value%r=1.0
        case(35);q%expressions(e)%value%l=.true.
        case(36);q%expressions(e)%value%real_kind=8
        case(37);q%expressions(e)%value%s='bad'
        case(38);q%symbols(s)%is_parameter=.true.
        case(39);q%symbols(s)%dummy_intent=1
        case(40);q%symbols(s)%scope=1
        case(41);q%symbols(s)%is_pointer=.true.
        case(42);q%symbols(s)%deferred_character=.true.
        case(43);q%symbols(s)%real_kind=8
        case(44);q%symbols(s)%rank=1
        case(45);q%symbols(s)%typ=ty_integer
        end select
        call expect(.not.valid_allocation_output(q,e,ty_character,0),'public malformed message')
        call expect(.not.valid_allocation_message(q,q%code(pc)),'public malformed controls')
        call expect(.not.valid_allocation_group(q,pc),'public malformed group')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code/=0,'adapter rejects mutation')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code/=0,'runtime rejects mutation')
    end do
    do which=1,3
        q=p
        select case(which)
        case(1);q%code(pc+1)%third=0
        case(2);q%code(pc)%third=p%ne+1
        case(3);q%code(pc)%third=p%code(pc)%a
        end select
        call expect(.not.valid_allocation_group(q,pc),'group ERRMSG consistency')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code/=0,'adapter rejects group consistency mutation')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code/=0,'runtime rejects group consistency mutation')
    end do
    print '(a,i0,a)','PASS: ',checks,' allocation ERRMSG checks'
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
