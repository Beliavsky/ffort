! SPDX-License-Identifier: MIT
! Descriptor-only automatic bounds: source checks, independent adapter checks,
! and direct-runtime validation of malformed IR and unallocated entry state.
program test_allocatable_spec_inquiries
    use, intrinsic :: iso_fortran_env, only: int64, output_unit, error_unit
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter :: nl=new_line('a')
    type(program_t) :: p,q
    type(diagnostic_t) :: d
    character(:),allocatable :: source,text
    character(160) :: label
    integer :: rank,intent,empty,repeat,which,checks,root,arg,dim,dummy,local,host

    checks=0
    ! Keep the public PRINT stream private so every rejection can independently
    ! prove that the procedure body produced no output.
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')

    do rank=1,3
        do intent=1,3,2
            do empty=0,1
                source=positive_source(rank,intent,empty==1)
                call fresh(source)
                call verify_frontend(source,p,d)
                call expect(d%code==0,'positive source adapter')
                do repeat=1,3
                    d=diagnostic_t()
                    call clear_output()
                    call execute_program(p,d)
                    call expect(d%code==0,'descriptor bounds and fresh independent frame')
                    call expect_empty_output('positive checks stay silent')
                end do
            end do
        end do
    end do

    ! These are runtime-policy negatives, not executable GNU Fortran oracles:
    ! the actual is unallocated when the specification inquiry is evaluated.
    do rank=1,3
        do intent=1,3,2
            do which=1,4
                select case(which)
                case(1);text='size(x)'
                case(2);text='size(x,'//number(rank)//')'
                case(3);text='lbound(x,'//number(rank)//')'
                case(4);text='ubound(x,'//number(rank)//')'
                end select
                source=inquiry_source(rank,intent,text)
                call fresh(source)
                call verify_frontend(source,p,d)
                call expect(d%code==0,'unallocated source is statically supported')
                call clear_output()
                d=diagnostic_t()
                call execute_program(p,d)
                call expect(d%code==2,'unallocated specification inquiry is a runtime error')
                call expect(allocated(d%message),'unallocated inquiry diagnostic exists')
                call expect(index(d%message,'unallocated')>0,'unallocated inquiry diagnostic')
                call expect_empty_output('unallocated inquiry fails before body PRINT')
            end do
        end do
    end do

    ! Source-level subset boundaries. These are deliberately not all described
    ! as invalid Fortran: mutable module data and pointer inquiries are outside
    ! this interpreter's bounded specification-expression contract.
    do which=1,5
        select case(which)
        case(1)
            text='subroutine work(x)'//nl//'integer,allocatable,intent(out)::x(:)'//nl
        case(2)
            text='subroutine work(x)'//nl//'integer,allocatable,optional,intent(in)::x(:)'//nl
        case(3)
            text='subroutine work()'//nl//'integer,allocatable::x(:)'//nl
        case(4)
            text='subroutine work()'//nl
        case(5)
            text='subroutine work(x)'//nl//'integer,pointer,intent(in)::x(:)'//nl
        end select
        source='module m'//nl
        if(which==4) source=source//'integer,allocatable::x(:)'//nl
        source=source//'contains'//nl//text//'integer::aa(size(x))'//nl// &
            'print *,999'//nl//'end subroutine'//nl//'end module'//nl// &
            'program main'//nl//'use m'//nl//'end program'
        d=diagnostic_t()
        call parse_subset(source,p,d)
        call expect(d%code==1,'unsupported specification-inquiry source rejected')
    end do

    ! Every mutation starts from honest source, then reaches the public runtime
    ! directly without reusing the adapter diagnostic. The gate itself is also
    ! checked so another earlier rejection cannot hide an overly broad rule.
    source=positive_source(3,1,.false.)
    call fresh(source)
    call verify_frontend(source,p,d)
    call expect(d%code==0,'mutation baseline adapter')
    root=p%symbols(symbol_named(p,'bydim',1))%upper_expr
    arg=p%expressions(root)%args(1)
    dim=p%expressions(root)%args(2)
    dummy=symbol_named(p,'x',1)
    local=symbol_named(p,'spare',1)
    host=symbol_named(p,'host',-1)
    call expect(valid_automatic_bound(p,root,1),'honest allocatable inquiry gate')
    do which=1,27
        q=p
        select case(which)
        case(1);q%symbols(dummy)%dummy_intent=2;label='ALLOCATABLE INTENT(OUT)'
        case(2);q%symbols(dummy)%is_optional=.true.;label='OPTIONAL ALLOCATABLE'
        case(3);q%expressions(arg)%symbol=local;label='local ALLOCATABLE'
        case(4);q%expressions(arg)%symbol=host;label='module ALLOCATABLE'
        case(5)
            q%symbols(dummy)%is_pointer=.true.;q%symbols(dummy)%is_allocatable=.false.
            label='POINTER inquiry source'
        case(6);q%symbols(dummy)%dummy_intent=0;label='missing ALLOCATABLE INTENT'
        case(7);q%symbols(dummy)%dummy_intent=4;label='invalid ALLOCATABLE INTENT'
        case(8);q%symbols(dummy)%scope=0;label='dummy outside procedure scope'
        case(9);q%symbols(dummy)%rank=0;label='scalar ALLOCATABLE inquiry source'
        case(10);q%symbols(dummy)%rank=4;label='rank-four ALLOCATABLE inquiry source'
        case(11);q%expressions(root)%typ=ty_real;label='non-INTEGER inquiry result'
        case(12);q%expressions(root)%rank=1;label='nonscalar inquiry result'
        case(13);q%expressions(root)%scope=0;label='inquiry outside procedure scope'
        case(14);deallocate(q%expressions(root)%args);label='missing inquiry arguments'
        case(15);q%expressions(root)%args(1)=0;label='zero inquiry argument'
        case(16);q%expressions(root)%args(1)=q%ne+1;label='out-of-range inquiry argument'
        case(17);q%expressions(arg)%kind=ex_section;label='non-whole inquiry source'
        case(18);q%expressions(arg)%symbol=0;label='missing inquiry source binding'
        case(19);q%expressions(arg)%symbol=q%ns+1;label='out-of-range inquiry source binding'
        case(20);q%expressions(dim)%typ=ty_real;label='non-INTEGER specification DIM'
        case(21);q%expressions(dim)%scope=0;label='specification DIM outside scope'
        case(22);q%expressions(root)%args=[integer::];label='zero inquiry arguments'
        case(23);q%expressions(root)%args=[arg,dim,dim];label='too many inquiry arguments'
        case(24);q%expressions(dim)%value%i=0_int64;label='DIM below one'
        case(25);q%expressions(dim)%value%i=4_int64;label='DIM exceeds source rank'
        case(26);q%symbols(dummy)%assumed_shape=.true.;label='ALLOCATABLE assumed-shape dummy'
        case(27);q%symbols(dummy)%is_automatic=.true.;label='ALLOCATABLE automatic dummy'
        end select
        ! DIM range is a runtime value check; a scalar INTEGER literal is a
        ! valid specification expression even when its value is out of range.
        if(which<=23.or.which>=26) call expect(.not.valid_automatic_bound(q,root,1),trim(label)//' gate')
        d=diagnostic_t()
        call verify_frontend(source,q,d)
        call expect(d%code==1,trim(label)//' adapter')
        d=diagnostic_t()
        call clear_output()
        call execute_program(q,d)
        call expect(d%code==2,trim(label)//' direct runtime')
        call expect_empty_output(trim(label)//' produces no output')
    end do

    ! Legal but different inquiry trees must not pass source/IR agreement.
    ! This is explicitly adapter-only coverage, not a runtime-policy negative.
    q=p;q%expressions(root)%op='lbound';q%expressions(root)%intrinsic_mask=3
    call expect(valid_automatic_bound(q,root,1),'legal alternate inquiry gate')
    d=diagnostic_t()
    call verify_frontend(source,q,d)
    call expect(d%code==1,'adapter rejects a different legal inquiry')

    close(output_unit)
    write(error_unit,'(a,i0,a)') 'PASS: ',checks,' allocatable specification-inquiry checks'
contains
    function positive_source(r,access,zero) result(s)
        integer,intent(in) :: r,access
        logical,intent(in) :: zero
        character(:),allocatable :: s,bounds,frozen,actual_bounds,indices
        integer :: k,total,extent,lo,hi
        bounds='';actual_bounds='';indices='';frozen='';total=1
        do k=1,r
            if(k>1) then
                bounds=bounds//',';actual_bounds=actual_bounds//',';indices=indices//','
            end if
            bounds=bounds//'lbound(x,'//number(k)//'):ubound(x,'//number(k)//')'
            select case(k)
            case(1);lo=-2;hi=0
            case(2);lo=4;hi=5
            case(3);lo=7;hi=8
            end select
            if(zero.and.k==r) hi=lo-1
            actual_bounds=actual_bounds//number(lo)//':'//number(hi)
            extent=max(0,hi-lo+1);total=total*extent
            if(extent==0) then
                lo=1;hi=0
            end if
            indices=indices//number(lo)
            frozen=frozen//'if(size(aa,'//number(k)//')/='//number(extent)// &
                '.or.lbound(aa,'//number(k)//')/='//number(lo)// &
                '.or.ubound(aa,'//number(k)//')/='//number(hi)//') error stop 11'//nl
        end do
        frozen=frozen//'if(size(aa)/='//number(total)//'.or.size(flat)/='//number(total)// &
            '.or.size(bydim)/='//number(extent)//') error stop 12'//nl
        s='module m'//nl//'integer,allocatable::host('//shape(r)//')'//nl//'contains'//nl// &
            'subroutine work(x)'//nl//'integer,allocatable,intent('//intent_name(access)//')::x('//shape(r)//')'//nl// &
            'integer,allocatable::spare('//shape(r)//')'//nl// &
            'integer::aa('//bounds//')'//nl//'integer::flat(size(x)),bydim(size(x,'//number(r)//'))'//nl// &
            frozen//'aa=3'//nl//'flat=5'//nl//'bydim=7'//nl// &
            'if(size(aa)>0) then'//nl//'if(aa('//indices//')/=3) error stop 13'//nl//'end if'//nl
        if(access==3) then
            s=s//'deallocate(x)'//nl//frozen//'allocate(x('//repeat_bounds(r)//'))'//nl//frozen
        end if
        s=s//'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
            'integer,allocatable::actual('//shape(r)//')'//nl//'allocate(actual('//actual_bounds//'))'//nl// &
            'call work(actual)'//nl//'end program'
    end function

    function inquiry_source(r,access,bound) result(s)
        integer,intent(in) :: r,access
        character(*),intent(in) :: bound
        character(:),allocatable :: s
        s='module m'//nl//'contains'//nl//'subroutine work(x)'//nl// &
            'integer,allocatable,intent('//intent_name(access)//')::x('//shape(r)//')'//nl// &
            'integer::aa('//bound//')'//nl//'print *,999'//nl//'end subroutine'//nl//'end module'//nl// &
            'program main'//nl//'use m'//nl//'integer,allocatable::actual('//shape(r)//')'//nl// &
            'call work(actual)'//nl//'end program'
    end function

    function shape(r) result(s)
        integer,intent(in) :: r
        character(:),allocatable :: s
        s=':'
        if(r>=2) s=s//',:'
        if(r==3) s=s//',:'
    end function

    function repeat_bounds(r) result(s)
        integer,intent(in) :: r
        character(:),allocatable :: s
        s='1:2'
        if(r>=2) s=s//',1:2'
        if(r==3) s=s//',1:2'
    end function

    function intent_name(access) result(s)
        integer,intent(in) :: access
        character(:),allocatable :: s
        s='in'
        if(access==3) s='inout'
    end function

    function number(n) result(s)
        integer,intent(in) :: n
        character(:),allocatable :: s
        character(24) :: buffer
        write(buffer,'(i0)') n
        s=trim(buffer)
    end function

    integer function symbol_named(prog,name,scope) result(found)
        type(program_t),intent(in) :: prog
        character(*),intent(in) :: name
        integer,intent(in) :: scope
        integer :: j
        found=0
        do j=1,prog%ns
            if(prog%symbols(j)%name/=name.or.prog%symbols(j)%scope/=scope) cycle
            found=j;return
        end do
        call expect(.false.,'required test symbol '//name)
    end function

    subroutine fresh(s)
        character(*),intent(in) :: s
        d=diagnostic_t()
        call parse_subset(s,p,d)
        call expect(d%code==0,'honest source parser')
    end subroutine

    subroutine clear_output()
        rewind(output_unit)
        endfile(output_unit)
        rewind(output_unit)
    end subroutine

    subroutine expect_empty_output(name)
        character(*),intent(in) :: name
        integer :: ios
        character(128) :: record
        rewind(output_unit)
        read(output_unit,'(a)',iostat=ios) record
        call expect(ios<0,name)
    end subroutine

    subroutine expect(ok,name)
        logical,intent(in) :: ok
        character(*),intent(in) :: name
        checks=checks+1
        if(ok) return
        write(error_unit,*) 'FAIL: ',name,' rank=',rank,' intent=',intent,' case=',which
        if(allocated(d%message)) write(error_unit,*) d%message
        error stop 'allocatable specification-inquiry regression'
    end subroutine
end program test_allocatable_spec_inquiries
