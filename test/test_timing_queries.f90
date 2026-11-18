! SPDX-License-Identifier: MIT
program test_timing_queries
    use, intrinsic :: iso_fortran_env, only: output_unit,error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::c,r,m'//nl//'real(8)::t'//nl//'call system_clock(c,r,m)'//nl// &
        'call cpu_time(t)'//nl//'end program'
    character(*),parameter::effect_source='program p'//nl//'print *,outer()'//nl// &
        'contains'//nl//'integer function outer()'//nl//'outer=inner()'//nl//'end function'//nl// &
        'integer function inner()'//nl//'integer::c'//nl//'real(8)::t'//nl// &
        'call system_clock(c)'//nl//'call cpu_time(t)'//nl//'inner=1'//nl//'end function'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::pc,cpu,e,s,j,which,checks,ios,caller,callee,stage
    character::ch
    checks=0;which=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'baseline adapter')
    pc=0;cpu=0
    do j=1,p%nc
        if(p%code(j)%op/=op_timing_query)cycle
        if(p%code(j)%d==1)pc=j
        if(p%code(j)%d==2)cpu=j
    end do
    call expect(pc>0.and.cpu>0,'opcode and modes')
    e=p%code(pc)%items(1);s=p%expressions(e)%symbol
    call expect(valid_timing_query(p,p%code(pc)),'public SYSTEM_CLOCK baseline')
    call expect(valid_timing_query(p,p%code(cpu)),'public CPU_TIME baseline')
    call reset_output();call execute_program(p,d)
    call expect(d%code==0,'real host baseline runtime')
    call no_output()
    do which=1,83
        q=p
        select case(which)
        case(1);q%code(pc)%d=0
        case(2);q%code(pc)%d=3
        case(3);q%code(pc)%scope=-1
        case(4);q%code(pc)%symbol=s
        case(5);q%code(pc)%a=1
        case(6);q%code(pc)%b=1
        case(7);q%code(pc)%c=1
        case(8);q%code(pc)%third=1
        case(9);q%code(pc)%target=1
        case(10);q%code(pc)%component=1
        case(11);q%code(pc)%generic_id=1
        case(12);q%code(pc)%bound_type=1
        case(13);q%code(pc)%bound_binding=1
        case(14);q%code(pc)%construct_name='bad'
        case(15);q%code(pc)%format='*'
        case(16);q%code(pc)%format_expr=e
        case(17);q%code(pc)%advance_mode=1
        case(18);deallocate(q%code(pc)%items)
        case(19);q%code(pc)%items=[e]
        case(20);q%code(pc)%items(1)=-1
        case(21);q%code(pc)%items(1)=q%ne+1
        case(22);q%code(pc)%items(2)=e
        case(23);q%expressions(e)%kind=ex_literal
        case(24);q%expressions(e)%scope=999
        case(25);q%expressions(e)%symbol=0
        case(26);q%expressions(e)%symbol=q%ns+1
        case(27);q%expressions(e)%parenthesized=.true.
        case(28);q%expressions(e)%typ=ty_real
        case(29);q%expressions(e)%real_kind=8
        case(30);q%expressions(e)%rank=1
        case(31);q%expressions(e)%extent=1
        case(32);q%expressions(e)%dims(3)=1
        case(33);q%expressions(e)%character_len=0
        case(34);q%expressions(e)%left=1
        case(35);q%expressions(e)%right=1
        case(36);q%expressions(e)%stride=1
        case(37);q%expressions(e)%left2=1
        case(38);q%expressions(e)%right2=1
        case(39);q%expressions(e)%stride2=1
        case(40);q%expressions(e)%left3=1
        case(41);q%expressions(e)%right3=1
        case(42);q%expressions(e)%stride3=1
        case(43);q%expressions(e)%third=1
        case(44);allocate(q%expressions(e)%args(0))
        case(45);q%expressions(e)%length_expr=1
        case(46);q%expressions(e)%constructor_kind_expr=1
        case(47);q%expressions(e)%constructor_owner=1
        case(48);q%expressions(e)%generic_id=1
        case(49);q%expressions(e)%bound_type=1
        case(50);q%expressions(e)%bound_binding=1
        case(51);q%expressions(e)%intrinsic_mask=1
        case(52);q%expressions(e)%op='+'
        case(53);q%expressions(e)%triplet(2)=.true.
        case(54);q%expressions(e)%value%tag=ty_integer
        case(55);q%expressions(e)%value%i=1
        case(56);q%expressions(e)%value%r=1
        case(57);q%expressions(e)%value%l=.true.
        case(58);q%expressions(e)%value%real_kind=8
        case(59);q%expressions(e)%value%s='bad'
        case(60);allocate(q%expressions(e)%value%record)
        case(61);q%symbols(s)%rank=1
        case(62);q%symbols(s)%is_allocatable=.true.
        case(63);q%symbols(s)%is_pointer=.true.
        case(64);q%symbols(s)%is_parameter=.true.
        case(65);q%symbols(s)%dummy_intent=1
        case(66);q%symbols(s)%is_class=.true.
        case(67);q%symbols(s)%is_intrinsic=.true.
        case(68);q%symbols(s)%deferred_character=.true.
        case(69);q%symbols(s)%character_len=0
        case(70);q%symbols(s)%real_kind=2
        case(71);q%symbols(s)%scope=999
        case(72);q%symbols(s)%assumed_shape=.true.
        case(73);q%symbols(s)%is_automatic=.true.
        case(74);q%symbols(s)%lower_expr=1
        case(75);q%symbols(s)%upper_expr=1
        case(76);q%symbols(s)%lower_expr2=1
        case(77);q%symbols(s)%upper_expr2=1
        case(78);q%symbols(s)%lower_expr3=1
        case(79);q%symbols(s)%upper_expr3=1
        case(80);q%symbols(s)%length_expr=1
        case(81);q%symbols(s)%dummy_intent=4
        case(82);q%symbols(s)%is_optional=.true.
        case(83);q%symbols(s)%is_dummy=.true.
        end select
        call expect(.not.valid_timing_query(q,q%code(pc)),'public mutant rejected')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code/=0,'independent source adapter rejected mutant')
        d=diagnostic_t();call reset_output();call execute_program(q,d)
        call expect(d%code/=0,'independent runtime rejected mutant')
        call no_output()
    end do
    q=p;q%code(cpu)%items(1)=0
    call expect(.not.valid_timing_query(q,q%code(cpu)),'CPU_TIME required output')
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code/=0,'runtime CPU_TIME required output')
    q=p;q%code(pc)%items=0
    call expect(valid_timing_query(q,q%code(pc)),'all optional omitted legal IR')
    d=diagnostic_t();call reset_output();call execute_program(q,d)
    call expect(d%code==0,'all optional omitted runtime')
    call no_output()
    d=diagnostic_t();call reset_output();call execute_program(p,d,max_steps=25_int64)
    call expect(d%code==2,'fixed clock query charge respects budget')
    call no_output()
    d=diagnostic_t();call parse_subset(effect_source,p,d)
    call expect(d%code==0,'effect parser')
    call verify_frontend(effect_source,p,d)
    call expect(d%code==0,'effect adapter')
    caller=0;callee=0
    do j=1,p%np
        if(p%procedures(j)%name=='outer')caller=j
        if(p%procedures(j)%name=='inner')callee=j
    end do
    call expect(caller>0.and.callee>0,'effect identities')
    do stage=1,2
        do which=1,4
            q=p
            select case(which)
            case(1);q%procedures(caller)%is_pure=.true.
            case(2);q%procedures(callee)%is_pure=.true.
            case(3);q%procedures(caller)%is_simple=.true.
            case(4);q%procedures(callee)%is_simple=.true.
            end select
            d=diagnostic_t();call reset_output()
            if(stage==1)then
                call verify_frontend(effect_source,q,d)
            else
                call execute_program(q,d)
            end if
            call expect(d%code==stage,'direct/transitive PURE/SIMPLE guard')
            call no_output()
        end do
    end do
    write(error_unit,'(a,i0)')'timing metadata checks: ',checks
contains
    subroutine reset_output()
        close(output_unit)
        open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    end subroutine
    subroutine no_output()
        rewind(output_unit);read(output_unit,'(a)',iostat=ios)ch
        call expect(ios<0,'no partial output')
    end subroutine
    subroutine expect(condition,label)
        logical,intent(in)::condition
        character(*),intent(in)::label
        checks=checks+1
        if(condition)return
        write(error_unit,*)'FAIL ',which,trim(label)
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
end program
