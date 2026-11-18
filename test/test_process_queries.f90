! SPDX-License-Identifier: MIT
program test_process_queries
    use, intrinsic :: iso_fortran_env, only: output_unit,error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(80)::name,other'//nl//'character(65536)::cwd'//nl// &
        'integer::n,stat,alternate'//nl// &
        'call get_command_argument(number=0,status=stat,length=n,value=name)'//nl// &
        'if(stat/=0.or.n/=len_trim(name)) stop 1'//nl// &
        'call getcwd(status=stat,count=cwd)'//nl//'if(stat/=0.or.len_trim(cwd)==0) stop 2'//nl// &
        'print "(a)",trim(name)'//nl//'end program'
    character(*),parameter::effect_source='program p'//nl//'implicit none'//nl// &
        'print *,outer()'//nl//'contains'//nl//'integer function outer()'//nl// &
        'outer=inner()'//nl//'end function'//nl//'integer function inner()'//nl// &
        'character(80)::name'//nl//'integer::n'//nl// &
        'call get_command_argument(0,value=name,length=n)'//nl//'inner=n'//nl// &
        'end function'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::pc,root,s,j,which,checks,ios,alternate,name_symbol,stage,caller,callee
    character(100)::line
    character(:),allocatable::changed
    checks=0;which=0
    call reset_output()
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'baseline adapter')
    pc=0;alternate=0
    do j=1,p%nc
        if(p%code(j)%op==op_process_query.and.p%code(j)%d==2) pc=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='alternate') alternate=j
    end do
    call expect(pc>0.and.alternate>0,'baseline identities')
    root=p%code(pc)%items(2);s=p%expressions(root)%symbol;name_symbol=s
    call expect(valid_process_query(p,p%code(pc)),'baseline public gate')
    do j=1,2
        d=diagnostic_t();call reset_output()
        if(j==1) then
            call execute_program(p,d,program_name='first.f90')
        else
            call execute_program(p,d,program_name='second.f90')
        end if
        call expect(d%code==0,'independent execution context')
        rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
        if(j==1) then
            call expect(ios==0.and.trim(line)=='first.f90','first logical program identity')
        else
            call expect(ios==0.and.trim(line)=='second.f90','second logical program identity')
        end if
    end do
    ! With no logical name override, the API snapshots only host argv[0].
    call get_command_argument(0,length=alternate,status=ios)
    call expect(ios==0,'native argument zero oracle')
    changed='program fallback'//nl//'integer::n,stat'//nl// &
        'call get_command_argument(0,length=n,status=stat)'//nl//'print *,n,stat'//nl//'end program'
    d=diagnostic_t();call parse_subset(changed,q,d)
    call expect(d%code==0,'API fallback parser')
    call verify_frontend(changed,q,d)
    call expect(d%code==0,'API fallback adapter')
    call reset_output();call execute_program(q,d)
    call expect(d%code==0,'API default process identity')
    rewind(output_unit);read(output_unit,*,iostat=ios) j,stage
    call expect(ios==0.and.j==alternate.and.stage==0,'API host argument zero snapshot')
    alternate=0
    do j=1,p%ns
        if(p%symbols(j)%name=='alternate') alternate=j
    end do
    do which=1,57
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
        case(14);q%code(pc)%construct_name='forged'
        case(15);q%code(pc)%format='*'
        case(16);q%code(pc)%format_expr=root
        case(17);q%code(pc)%advance_mode=1
        case(18);deallocate(q%code(pc)%items)
        case(19);q%code(pc)%items=q%code(pc)%items(:3)
        case(20);q%code(pc)%items(1)=0
        case(21);q%code(pc)%items(1)=q%ne+1
        case(22);q%code(pc)%items(2)=-1
        case(23);q%code(pc)%items(2)=q%ne+1
        case(24);q%code(pc)%items(3)=q%code(pc)%items(4)
        case(25);q%code(pc)%items(1)=q%code(pc)%items(3)
        case(26);q%expressions(q%code(pc)%items(1))%real_kind=8
        case(27);q%expressions(q%code(pc)%items(1))%typ=ty_real
        case(28);q%expressions(q%code(pc)%items(1))%rank=1
        case(29);q%expressions(root)%kind=ex_literal
        case(30);q%expressions(root)%parenthesized=.true.
        case(31);q%expressions(root)%scope=1
        case(32);q%expressions(root)%typ=ty_integer
        case(33);q%expressions(root)%real_kind=8
        case(34);q%expressions(root)%rank=1
        case(35);q%expressions(root)%extent=1
        case(36);q%expressions(root)%dims(2)=1
        case(37);q%expressions(root)%left=1
        case(38);q%expressions(root)%right=1
        case(39);q%expressions(root)%stride=1
        case(40);q%expressions(root)%left2=1
        case(41);q%expressions(root)%third=1
        case(42);q%expressions(root)%args=[1]
        case(43);q%expressions(root)%length_expr=1
        case(44);q%expressions(root)%constructor_kind_expr=1
        case(45);q%expressions(root)%generic_id=1
        case(46);q%expressions(root)%intrinsic_mask=1
        case(47);q%expressions(root)%op='forged'
        case(48);q%expressions(root)%character_len=79
        case(49);q%expressions(root)%triplet(2)=.true.
        case(50);q%symbols(s)%is_dummy=.true.
        case(51);q%symbols(s)%is_optional=.true.
        case(52);q%symbols(s)%is_parameter=.true.
        case(53);q%symbols(s)%is_pointer=.true.
        case(54);q%symbols(s)%is_class=.true.
        case(55);q%symbols(s)%is_intrinsic=.true.
        case(56);q%symbols(s)%dummy_intent=1
        case(57);q%symbols(s)%scope=1
        end select
        call expect(.not.valid_process_query(q,q%code(pc)),'mutated public gate')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'mutated adapter rejects')
        d=diagnostic_t();call reset_output();call execute_program(q,d,program_name='probe.f90')
        call expect(d%code==2,'mutated direct runtime rejects')
        call expect(allocated(d%message),'runtime diagnostic present')
        rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
        call expect(ios<0,'failed query produces no partial output')
    end do
    q=p;q%expressions(q%code(pc)%items(3))%symbol=alternate
    call expect(valid_process_query(q,q%code(pc)),'alternate INTEGER output is structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'different source output identity rejected')
    q=p;q%code(pc)%items(2)=0
    call expect(valid_process_query(q,q%code(pc)),'omitted VALUE is structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'different source optional presence rejected')
    changed=source;j=index(changed,'length=n');changed=changed(:j-1)//'length=stat'//changed(j+8:)
    d=diagnostic_t();call verify_frontend(changed,p,d)
    call expect(d%code==1,'changed keyword binding rejected')
    d=diagnostic_t();call reset_output();call execute_program(p,d,program_name=repeat('x',65537))
    call expect(d%code==2,'program name context cap')
    rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
    call expect(ios<0,'invalid process context silent')
    d=diagnostic_t();call reset_output();call execute_program(p,d,max_steps=70_int64,program_name='probe.f90')
    call expect(d%code==2,'process query consumes shared work budget')
    rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
    call expect(ios<0,'budget exhaustion silent')
    d=diagnostic_t();call parse_subset(effect_source,p,d)
    call expect(d%code==0,'nested effect parser')
    call verify_frontend(effect_source,p,d)
    call expect(d%code==0,'nested effect adapter')
    call reset_output();call execute_program(p,d,program_name='nested.f90')
    call expect(d%code==0,'nested context execution')
    rewind(output_unit);read(output_unit,*,iostat=ios) j
    call expect(ios==0.and.j==10,'nested call inherits logical invocation')
    caller=0;callee=0
    do j=1,p%np
        if(p%procedures(j)%name=='outer') caller=j
        if(p%procedures(j)%name=='inner') callee=j
    end do
    call expect(caller>0.and.callee>0,'nested effect identities')
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
            if(stage==1) then
                call verify_frontend(effect_source,q,d)
            else
                call execute_program(q,d,program_name='nested.f90')
            end if
            call expect(d%code==stage,'direct and transitive PURE/SIMPLE query rejection')
            rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
            call expect(ios<0,'forbidden query cannot publish pending output')
        end do
    end do
    write(error_unit,'(a,i0,a)') 'process queries native: ',checks,' checks passed'
contains
    subroutine reset_output()
        close(output_unit)
        open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok) return
        write(error_unit,*) 'FAIL ',checks,which,': ',label
        if(allocated(d%message)) write(error_unit,*) d%message
        error stop 1
    end subroutine
end program
