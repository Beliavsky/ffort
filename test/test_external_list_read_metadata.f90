! SPDX-License-Identifier: MIT
! Independent 0.47 public-IR/producer checks. Source only until the candidate build exists.
program test_external_list_read_metadata
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::u,v,s,n'//nl//'real(8)::x(1,2)'//nl//'character(4)::c(1,1,2)'//nl// &
        'read(u,*,iostat=s)n,x,c'//nl//'backspace(unit=u,iostat=s)'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::rp,bp,j,k,checks,which,e,alt
    character(:),allocatable::scoped
    checks=0;which=0;rp=0;bp=0;alt=0
    call parse_subset(source,p,d);call expect(d%code==0,'parser')
    call verify_frontend(source,p,d);call expect(d%code==0,'independent producer')
    do j=1,p%nc
        if(p%code(j)%op==op_read_external)rp=j
        if(p%code(j)%op==op_backspace)bp=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='v')alt=j
    end do
    call expect(rp>0.and.bp>0.and.alt>0,'instruction and unit identities')
    call expect(.not.allocated(p%code(rp)%format),'unallocated format means external list input')
    call expect(valid_external_read(p,p%code(rp)),'list READ public gate')
    call expect(valid_backspace(p,p%code(bp)),'BACKSPACE public gate')
    call expect(.not.valid_internal_read(p,p%code(rp)),'external READ is not internal READ')
    q=p;q%code(rp)%items=[integer::]
    call expect(valid_external_read(q,q%code(rp)),'empty list structurally permitted')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'changed input list source binding fails')
    do which=1,18
        q=p;e=q%code(rp)%items(1)
        select case(which)
        case(1);q%code(rp)%format='*'
        case(2);q%code(rp)%format='(a)'
        case(3);deallocate(q%code(rp)%items)
        case(4);q%code(rp)%items=[e,e]
        case(5);q%code(rp)%items(1)=q%code(rp)%a
        case(6);q%code(rp)%items(1)=q%code(rp)%b
        case(7);q%code(rp)%a=0
        case(8);q%code(rp)%b=q%ne+1
        case(9);q%code(rp)%c=1
        case(10);q%code(rp)%scope=-1
        case(11);q%code(rp)%format_expr=q%code(rp)%a
        case(12);q%expressions(e)%parenthesized=.true.
        case(13);q%expressions(e)%dims(1)=1_int64
        case(14);q%expressions(e)%value%i=1_int64
        case(15);q%symbols(q%expressions(e)%symbol)%dummy_intent=1
        case(16);q%expressions(q%code(rp)%items(3))%character_len=5
        case(17);q%expressions(q%code(rp)%items(2))%extent=99_int64
        case(18);q%code(rp)%advance_mode=1
        end select
        call expect(.not.valid_external_read(q,q%code(rp)),'mutated READ gate fails')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'mutated READ independent producer fails')
    end do
    do which=1,23
        q=p
        select case(which)
        case(1);q%code(bp)%op=op_read_external
        case(2);q%code(bp)%a=0
        case(3);q%code(bp)%a=q%ne+1
        case(4);q%code(bp)%b=-1
        case(5);q%code(bp)%b=q%code(bp)%a
        case(6);q%code(bp)%symbol=1
        case(7);q%code(bp)%c=1
        case(8);q%code(bp)%d=1
        case(9);q%code(bp)%third=1
        case(10);q%code(bp)%target=1
        case(11);q%code(bp)%component=1
        case(12);q%code(bp)%generic_id=1
        case(13);q%code(bp)%bound_type=1
        case(14);q%code(bp)%bound_binding=1
        case(15);q%code(bp)%construct_name='forged'
        case(16);q%code(bp)%format_expr=q%code(bp)%a
        case(17);q%code(bp)%advance_mode=1
        case(18);q%code(bp)%format=''
        case(19);q%code(bp)%items=[integer::]
        case(20);q%expressions(q%code(bp)%a)%parenthesized=.true.
        case(21);q%expressions(q%code(bp)%b)%rank=1
        case(22);q%symbols(q%expressions(q%code(bp)%a)%symbol)%is_parameter=.true.
        case(23);q%code(bp)%scope=-1
        end select
        call expect(.not.valid_backspace(q,q%code(bp)),'mutated BACKSPACE gate fails')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'mutated BACKSPACE independent producer fails')
    end do
    q=p;q%expressions(q%code(bp)%a)%symbol=alt
    call expect(valid_backspace(q,q%code(bp)),'alternate unit structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'alternate BACKSPACE unit bound to source')
    scoped='module m'//nl//'contains'//nl//'subroutine f(u)'//nl// &
        'integer,intent(in)::u'//nl//'integer::n,s'//nl// &
        'read(u,*,iostat=s)n'//nl//'backspace(u,iostat=s)'//nl// &
        'end subroutine'//nl//'end module'//nl//'program p'//nl//'end program'
    d=diagnostic_t();call parse_subset(scoped,p,d);call expect(d%code==0,'impure procedure parses')
    call verify_frontend(scoped,p,d);call expect(d%code==0,'impure procedure producer')
    do j=1,p%nc
        if(p%code(j)%op/=op_read_external.and.p%code(j)%op/=op_backspace)cycle
        do which=1,3
            q=p;k=q%code(j)%scope
            select case(which)
            case(1);q%procedures(k)%is_pure=.true.
            case(2);q%procedures(k)%is_simple=.true.
            case(3);q%procedures(k)%is_subroutine=.false.;q%procedures(k)%has_impure_prefix=.false.
            end select
            if(q%code(j)%op==op_read_external)then
                call expect(.not.valid_external_read(q,q%code(j)),'READ effect metadata fails')
            else
                call expect(.not.valid_backspace(q,q%code(j)),'BACKSPACE effect metadata fails')
            end if
        end do
    end do
    write(error_unit,'(a,i0,a)')'external list READ metadata: ',checks,' checks passed'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)'FAIL ',checks,which,': ',label
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
end program
