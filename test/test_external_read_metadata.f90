! SPDX-License-Identifier: MIT
program test_external_read_metadata
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::prefix='program p'//nl//'implicit none'//nl// &
        'integer::unit,other_unit,stat,other_stat,n'//nl// &
        'character(40)::line,other_line'//nl
    character(*),parameter::source=prefix// &
        'read(unit, "(a)", iostat=stat) line'//nl//'end program'
    character(*),parameter::character_source='program p'//nl//'implicit none'//nl// &
        'character(100)::line'//nl//'character(8)::word,a(2),b(1,2),c(1,1,2)'//nl// &
        'character(:),allocatable::d0,d(:),e(:,:),f(:,:,:)'//nl// &
        'character(9),allocatable::g0'//nl//'integer::stat'//nl// &
        'read(line,*,iostat=stat) word,a,b,c,d0,d,e,f,g0'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::j,k,pc,unit,target,status,which,checks,alternate_unit,alternate_line
    character(:),allocatable::changed
    checks=0;which=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'external source parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'external source independent producer')
    pc=0;alternate_unit=0;alternate_line=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_external) pc=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='other_unit') alternate_unit=j
        if(p%symbols(j)%name=='other_line') alternate_line=j
    end do
    call expect(pc>0.and.alternate_unit>0.and.alternate_line>0,'external identities')
    unit=p%code(pc)%a;target=p%code(pc)%items(1);status=p%code(pc)%b
    call expect(valid_external_read(p,p%code(pc)),'external public gate')
    call expect(.not.valid_internal_read(p,p%code(pc)),'external not an internal opcode')
    do which=1,56
        q=p
        select case(which)
        case(1);q%code(pc)%op=op_read_internal
        case(2);q%code(pc)%a=0
        case(3);q%code(pc)%a=q%ne+1
        case(4);q%code(pc)%b=-1
        case(5);q%code(pc)%b=q%ne+1
        case(6);q%code(pc)%b=unit
        case(7);q%code(pc)%symbol=1
        case(8);q%code(pc)%c=1
        case(9);q%code(pc)%d=1
        case(10);q%code(pc)%third=1
        case(11);q%code(pc)%target=1
        case(12);q%code(pc)%component=1
        case(13);q%code(pc)%generic_id=1
        case(14);q%code(pc)%bound_type=1
        case(15);q%code(pc)%bound_binding=1
        case(16);q%code(pc)%construct_name='forged'
        case(17);q%code(pc)%format_expr=unit
        case(18);q%code(pc)%advance_mode=1
        case(19);deallocate(q%code(pc)%format)
        case(20);q%code(pc)%format='*'
        case(21);q%code(pc)%format='(a4)'
        case(22);q%code(pc)%format='(2a)'
        case(23);q%code(pc)%format='(a/)'
        case(24);q%code(pc)%format='(a,a)'
        case(25);deallocate(q%code(pc)%items)
        case(26);q%code(pc)%items=[integer::]
        case(27);q%code(pc)%items=[target,target]
        case(28);q%code(pc)%items=[unit]
        case(29);q%code(pc)%items=[0]
        case(30);q%code(pc)%items=[q%ne+1]
        case(31);q%expressions(unit)%parenthesized=.true.
        case(32);q%expressions(target)%parenthesized=.true.
        case(33);q%expressions(target)%character_len=41
        case(34);q%expressions(target)%extent=1_int64
        case(35);q%expressions(target)%dims(1)=1_int64
        case(36);q%expressions(target)%triplet(2)=.true.
        case(37);q%expressions(target)%length_expr=unit
        case(38);q%expressions(target)%value%tag=ty_character
        case(39);q%expressions(target)%value%s='forged'
        case(40);q%expressions(target)%left=1
        case(41);q%expressions(target)%constructor_kind_expr=1
        case(42);q%expressions(target)%args=[unit]
        case(43);q%expressions(target)%scope=1
        case(44);q%symbols(q%expressions(target)%symbol)%dummy_intent=1
        case(45);q%symbols(q%expressions(target)%symbol)%is_parameter=.true.
        case(46);q%symbols(q%expressions(target)%symbol)%is_pointer=.true.
        case(47);q%symbols(q%expressions(target)%symbol)%is_class=.true.
        case(48);q%symbols(q%expressions(target)%symbol)%is_intrinsic=.true.
        case(49)
            q%symbols(q%expressions(target)%symbol)%real_kind=8
            q%expressions(target)%real_kind=8
        case(50);q%expressions(status)%rank=1
        case(51);q%expressions(unit)%character_len=0
        case(52);q%expressions(unit)%extent=1_int64
        case(53);q%expressions(unit)%dims(1)=1_int64
        case(54);q%symbols(q%expressions(unit)%symbol)%is_parameter=.true.
        case(55);q%code(pc)%scope=-1
        case(56);q%code(pc)%a=target
        end select
        if(which==19) then
            ! An absent format now denotes structurally valid list-directed input.
            call expect(valid_external_read(q,q%code(pc)),'list format structurally valid')
        else
            call expect(.not.valid_external_read(q,q%code(pc)),'external mutated public gate')
        end if
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'external mutated independent producer rejects')
    end do
    q=p;q%expressions(unit)%symbol=alternate_unit
    call expect(valid_external_read(q,q%code(pc)),'alternate unit structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'different unit source binding rejected')
    q=p;q%expressions(target)%symbol=alternate_line
    call expect(valid_external_read(q,q%code(pc)),'alternate target structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'different target source binding rejected')
    q=p;q%code(pc)%format='(A)'
    call expect(valid_external_read(q,q%code(pc)),'capital A structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'exact literal format spelling bound to source')
    call accept_statement('read(unit=unit,fmt=" ( A ) ",iostat=stat) line')
    call accept_statement("read(unit,'(a)') line")
    call reject_statement('read(10,"(a)") line')
    call reject_statement('read(*,"(a)") line')
    call accept_statement('read(unit,*) line')
    call reject_statement('read(unit,"(a4)") line')
    call reject_statement('read(unit,"(2a)") line')
    call reject_statement('read(unit,"(a/)") line')
    call reject_statement('read(unit,"(a,a)") line')
    call reject_statement('read(unit,line) line')
    call reject_statement('read(unit,"(a)",iostat=unit) line')
    call reject_statement('read(unit,"(a)",iostat=stat) line,other_line')
    call reject_statement('read(unit,"(a)")')
    call reject_statement('read(unit,"(a)") n')
    call reject_statement('read(unit,"(a)") line(1:2)')
    call reject_statement('read((unit),"(a)") line')
    call reject_statement('read(unit,"(a)",end=100) line')
    call reject_statement('read(unit,"(a)",iomsg=other_line) line')
    call reject_statement('read(unit,"(a)",advance="no") line')
    call reject_statement('read(line,*) line')
    changed=prefix//'character(:),allocatable::buffer,input'//nl// &
        'read(unit,"(a)",iostat=stat) buffer'//nl// &
        'read(input,*,iostat=stat) buffer'//nl//'end program'
    d=diagnostic_t();call parse_subset(changed,q,d)
    call expect(d%code==0,'unallocated scalar CHARACTER metadata parses')
    call verify_frontend(changed,q,d)
    call expect(d%code==0,'unallocated scalar CHARACTER metadata producer agrees')
    changed='module m'//nl//'contains'//nl//'subroutine s(unit)'//nl// &
        'integer,intent(in)::unit'//nl//'character(10)::line'//nl// &
        'read(unit,"(a)") line'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'end program'
    d=diagnostic_t();call parse_subset(changed,q,d)
    call expect(d%code==0,'external READ impure subroutine parser')
    call verify_frontend(changed,q,d)
    call expect(d%code==0,'external READ impure subroutine producer')
    do j=1,q%nc
        if(q%code(j)%op/=op_read_external) cycle
        q%procedures(q%code(j)%scope)%is_pure=.true.
        call expect(.not.valid_external_read(q,q%code(j)),'external READ forged PURE metadata')
        q%procedures(q%code(j)%scope)%is_pure=.false.
        q%procedures(q%code(j)%scope)%is_simple=.true.
        call expect(.not.valid_external_read(q,q%code(j)),'external READ forged SIMPLE metadata')
    end do
    do j=1,2
        changed='pure '
        if(j==2) changed='simple '
        changed='module m'//nl//'contains'//nl//changed//'subroutine s(unit)'//nl// &
            'integer,intent(in)::unit'//nl//'character(10)::line'//nl// &
            'read(unit,"(a)") line'//nl//'end subroutine'//nl//'end module'//nl// &
            'program p'//nl//'end program'
        d=diagnostic_t();call parse_subset(changed,q,d)
        call expect(d%code==1,'external READ rejected in PURE/SIMPLE')
    end do
    d=diagnostic_t();call parse_subset(character_source,p,d)
    call expect(d%code==0,'CHARACTER internal scalar and rank1-3 parser')
    call verify_frontend(character_source,p,d)
    call expect(d%code==0,'CHARACTER internal independent producer')
    do j=1,p%nc
        if(p%code(j)%op==op_read_internal) pc=j
    end do
    call expect(valid_internal_read(p,p%code(pc)),'CHARACTER internal public gate')
    do j=1,size(p%code(pc)%items)
        k=p%code(pc)%items(j)
        q=p;q%expressions(k)%character_len=99
        call expect(.not.valid_internal_read(q,q%code(pc)),'CHARACTER length mutation rejects')
        q=p;q%expressions(k)%dims(1)=99_int64
        call expect(.not.valid_internal_read(q,q%code(pc)),'CHARACTER dimensions mutation rejects')
        q=p;q%expressions(k)%extent=99_int64
        call expect(.not.valid_internal_read(q,q%code(pc)),'CHARACTER extent mutation rejects')
    end do
    q=p;q%code(pc)%items(1)=q%code(pc)%a
    call expect(.not.valid_internal_read(q,q%code(pc)),'internal file-target alias rejected')
    write(error_unit,'(a,i0,a)') 'external READ metadata: ',checks,' checks passed'
contains
    subroutine accept_statement(statement)
        character(*),intent(in)::statement
        d=diagnostic_t();call parse_subset(prefix//statement//nl//'end program',q,d)
        call expect(d%code==0,'external accepted statement parser')
        call verify_frontend(prefix//statement//nl//'end program',q,d)
        call expect(d%code==0,'external accepted statement producer')
    end subroutine
    subroutine reject_statement(statement)
        character(*),intent(in)::statement
        d=diagnostic_t();call parse_subset(prefix//statement//nl//'end program',q,d)
        call expect(d%code==1,'external unsupported statement rejected')
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
