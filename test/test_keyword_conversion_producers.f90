! SPDX-License-Identifier: MIT
! Conversion types must survive producer signature collection and keywords.
program test_keyword_conversion_producers
    use fortfront_compiler
    use fortfront_ast, only: call_or_subscript_node
    use type_system_unified, only: mono_type_t, TINT, TREAL, TARRAY
    implicit none
    character(*), parameter :: nl = new_line('a')
    type(compiler_frontend_options_t) :: opts
    type(compiler_frontend_result_t) :: front
    type(resolved_type_query_t) :: resolved
    type(mono_type_t) :: inferred
    integer :: i, rank, expected, count, arrays, matrices

    opts%input_mode = INPUT_MODE_STANDARD
    opts%operating_mode = OPERATING_MODE_STRICT
    opts%standardize = .false.
    opts%run_semantics = .true.
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'real :: ar(3), rr, ar2(2,3)'//nl//'integer :: ai(3), ii, ai2(2,3)'//nl// &
        'ar=2.0'//nl//'ai=3'//nl//'ar2=2.0'//nl//'ai2=3'//nl// &
        'ii=combine(first=2,second=int(3.0),third=4)'//nl// &
        'ii=combine(third=int(a=4.0),first=2,second=int(real(3)))'//nl// &
        'rr=take_real(x=real(int(3.0)))'//nl// &
        'rr=take_real(x=real(a=int(a=3.0)))'//nl// &
        'rr=sum(array=ar,dim=int(a=real(a=1)))'//nl// &
        'ii=sum(array=int(a=ar),dim=int(1.0))'//nl// &
        'rr=sum(array=real(a=ai),dim=int(1.0))'//nl// &
        'call take_int_array(arr=int(ar))'//nl// &
        'call take_int_array(arr=int(a=real(a=ai)))'//nl// &
        'call take_real_array(arr=real(ai))'//nl// &
        'call take_real_array(arr=real(a=int(a=ar)))'//nl// &
        'call take_int_matrix(arr=int(a=ar2))'//nl// &
        'call take_real_matrix(arr=real(a=ai2))'//nl// &
        'contains'//nl// &
        'integer function combine(first,second,third)'//nl// &
        'integer,intent(in)::first,second,third'//nl// &
        'combine=100*first+10*second+third'//nl//'end function'//nl// &
        'real function take_real(x)'//nl//'real,intent(in)::x'//nl// &
        'take_real=x'//nl//'end function'//nl// &
        'subroutine take_int_array(arr)'//nl//'integer,intent(in)::arr(:)'//nl// &
        'end subroutine'//nl//'subroutine take_real_array(arr)'//nl// &
        'real,intent(in)::arr(:)'//nl//'end subroutine'//nl// &
        'subroutine take_int_matrix(arr)'//nl//'integer,intent(in)::arr(:,:)'//nl// &
        'end subroutine'//nl//'subroutine take_real_matrix(arr)'//nl// &
        'real,intent(in)::arr(:,:)'//nl//'end subroutine'//nl//'end program', front, opts)
    call require_success()
    count = 0
    arrays = 0
    matrices = 0
    do i = 1, front%arena%entry_count
        if (.not. front%arena%has_node_at(i)) cycle
        select type (node => front%arena%entries(i)%node)
        type is (call_or_subscript_node)
            if (.not. node%is_intrinsic) cycle
            select case (node%name)
            case ('int')
                expected = TINT
            case ('real')
                expected = TREAL
            case default
                cycle
            end select
            count = count + 1
            inferred = node%inferred_type
            call inferred%sync_from_arena()
            rank = 0
            do while (inferred%kind == TARRAY)
                rank = rank + 1
                inferred = inferred%get_arg(1)
                call inferred%sync_from_arena()
            end do
            if (inferred%kind /= expected) error stop 'conversion inference corrupted'
            resolved = query_resolved_type(front%arena, i)
            if (.not. resolved%found .or. resolved%type_kind /= expected .or. &
                resolved%rank /= rank) error stop 'conversion metadata disagreement'
            if (rank == 1) arrays = arrays + 1
            if (rank == 2) matrices = matrices + 1
        end select
    end do
    if (count /= 22) then
        print *, 'conversion count', count
        error stop 'conversion coverage missing'
    end if
    if (arrays /= 8) then
        print *, 'array conversion count', arrays
        error stop 'elemental conversion rank lost'
    end if

    if (matrices /= 2) error stop 'rank-two conversion shape lost'

    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'call sink(x=real(3))'//nl//'contains'//nl//'subroutine sink(x)'//nl// &
        'integer,intent(in)::x'//nl//'end subroutine'//nl//'end program', front, opts)
    if (front%success()) error stop 'REAL conversion accepted for INTEGER dummy'
    call require_mismatch()
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'call sink(x=int(3.0))'//nl//'contains'//nl//'subroutine sink(x)'//nl// &
        'real,intent(in)::x'//nl//'end subroutine'//nl//'end program', front, opts)
    if (front%success()) error stop 'INT conversion accepted for REAL dummy'
    call require_mismatch()
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'real :: a(3)'//nl//'a=1.0'//nl//'call sink(x=int(a))'//nl// &
        'contains'//nl//'subroutine sink(x)'//nl// &
        'real,intent(in)::x(:)'//nl//'end subroutine'//nl//'end program', front, opts)
    if (front%success()) error stop 'INTEGER converted array accepted for REAL dummy'
    call require_mismatch()
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'integer :: a(3)'//nl//'a=1'//nl//'call sink(x=real(a))'//nl// &
        'contains'//nl//'subroutine sink(x)'//nl// &
        'integer,intent(in)::x(:)'//nl//'end subroutine'//nl//'end program', front, opts)
    if (front%success()) error stop 'REAL converted array accepted for INTEGER dummy'
    call require_mismatch()
contains
    subroutine require_success()
        if (front%success()) return
        if (allocated(front%error_msg)) print *, front%error_msg
        error stop 'conversion producer rejected valid source'
    end subroutine require_success

    subroutine require_mismatch()
        if (.not. allocated(front%error_msg)) error stop 'missing conversion diagnostic'
        if (index(front%error_msg, 'Type mismatch in call') > 0) return
        print *, front%error_msg
        error stop 'wrong conversion mismatch diagnostic'
    end subroutine require_mismatch
end program test_keyword_conversion_producers
