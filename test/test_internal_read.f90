! SPDX-License-Identifier: MIT
program test_internal_read
    use, intrinsic :: iso_fortran_env, only: output_unit,error_unit
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(20)::text,other'//nl//'integer::n,a(2),stat,m'//nl// &
        'text="3 4 5"'//nl//'other="3 4 5"'//nl// &
        'read(text,*,iostat=stat) n,a'//nl// &
        'if(stat/=0.or.n/=3.or.any(a/=[4,5])) stop 1'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::pc,e,s,j,which,checks,ios,other,alternate
    character(30)::line
    character(:),allocatable::changed
    checks=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d)
    call expect(d%code==0,'source baseline parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'source baseline adapter')
    pc=0;other=0;alternate=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_internal) pc=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='other') other=j
        if(p%symbols(j)%name=='m') alternate=j
    end do
    call expect(pc>0.and.other>0.and.alternate>0,'baseline identities')
    call expect(valid_internal_read(p,p%code(pc)),'baseline public gate')
    do j=1,2
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'repeat independent execution')
    end do
    e=p%code(pc)%items(1);s=p%expressions(e)%symbol
    do which=1,43
        q=p
        select case(which)
        case(1);q%code(pc)%a=0
        case(2);q%code(pc)%a=q%ne+1
        case(3);q%code(pc)%b=-1
        case(4);q%code(pc)%b=q%ne+1
        case(5);q%code(pc)%symbol=s
        case(6);q%code(pc)%c=1
        case(7);q%code(pc)%d=1
        case(8);q%code(pc)%third=1
        case(9);q%code(pc)%target=1
        case(10);q%code(pc)%component=1
        case(11);q%code(pc)%generic_id=1
        case(12);q%code(pc)%bound_type=1
        case(13);q%code(pc)%bound_binding=1
        case(14);q%code(pc)%construct_name='forged'
        case(15);q%code(pc)%format='*'
        case(16);deallocate(q%code(pc)%items)
        case(17);q%code(pc)%items=[(e,j=1,65)]
        case(18);q%code(pc)%items(1)=0
        case(19);q%code(pc)%items(1)=q%ne+1
        case(20);q%code(pc)%items(2)=e
        case(21);q%code(pc)%b=e
        case(22);q%expressions(e)%parenthesized=.true.
        case(23);q%expressions(e)%kind=ex_literal
        case(24);q%expressions(e)%typ=ty_real
        case(25);q%expressions(e)%rank=1
        case(26);q%expressions(e)%real_kind=8
        case(27);q%expressions(e)%left=1
        case(28);q%expressions(e)%right=1
        case(29);q%expressions(e)%stride=1
        case(30);q%expressions(e)%third=1
        case(31);q%expressions(e)%args=[1]
        case(32);q%expressions(e)%constructor_kind_expr=1
        case(33);q%expressions(e)%op='forged'
        case(34);q%symbols(s)%dummy_intent=1
        case(35);q%symbols(s)%is_parameter=.true.
        case(36);q%symbols(s)%is_pointer=.true.
        case(37);q%symbols(s)%is_class=.true.
        case(38);q%symbols(s)%is_intrinsic=.true.
        case(39);q%code(pc)%scope=-1
        case(40);q%expressions(q%code(pc)%a)%symbol=s
        case(41);q%code(pc)%b=q%code(pc)%items(2)
        case(42)
            q%symbols(q%expressions(q%code(pc)%a)%symbol)%real_kind=8
            q%expressions(q%code(pc)%a)%real_kind=8
        case(43);q%expressions(e)%scope=1
        end select
        call expect(.not.valid_internal_read(q,q%code(pc)),'mutated public gate')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'mutated adapter rejects')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'mutated direct runtime rejects')
        call expect(allocated(d%message),'mutated runtime gives diagnostic')
        rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
        call expect(ios<0,'mutated direct runtime silent')
    end do
    ! Honest alternate targets/files can be valid IR; only the independent
    ! producer can establish the original source's exact binding identity.
    q=p;q%expressions(q%code(pc)%a)%symbol=other
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'same-valued different internal file rejected')
    q=p;q%expressions(e)%symbol=alternate
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'same-type different input target rejected')
    changed=source
    j=index(changed,'iostat=stat');changed(j:j+10)='iostat=m   '
    d=diagnostic_t();call verify_frontend(changed,p,d)
    call expect(d%code==1,'different source status binding rejected')
    write(error_unit,'(a,i0,a)') 'internal READ native: ',checks,' checks passed'
contains
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
