! SPDX-License-Identifier: MIT
! Regression coverage for local FortFront patch 0004. This calls the real
! strict frontend, rather than accepting a failed semantic pass in the adapter.
program test_named_real_kind_frontend
    use fortfront_compiler
    use fortfront_ast, only: function_def_node, declaration_node, call_or_subscript_node
    implicit none
    character(*), parameter :: nl = new_line('a')
    type(compiler_frontend_options_t) :: opts
    type(compiler_frontend_result_t) :: front
    type(declaration_query_t) :: decl
    type(resolved_type_query_t) :: typ
    integer :: i, found

    opts%input_mode = INPUT_MODE_STANDARD
    opts%operating_mode = OPERATING_MODE_STRICT
    opts%standardize = .false.
    opts%run_semantics = .true.

    call check('imported named kind', 'use iso_fortran_env, only: real64'//nl// &
        'integer, parameter :: wp = real64', 'wp', 'wp', &
        '1.0_wp', .true.)
    call check('imported named kind rejects real32', &
        'use iso_fortran_env, only: real64'//nl// &
        'integer, parameter :: wp = real64', 'wp', 'wp', '1.0', .false.)
    call check('renamed intrinsic kind', &
        'use iso_fortran_env, only: imported_kind => real64'//nl// &
        'integer, parameter :: wp = imported_kind', 'wp', 'wp', '1.0_wp', .true.)
    call check('renamed intrinsic kind rejects real32', &
        'use iso_fortran_env, only: imported_kind => real64'//nl// &
        'integer, parameter :: wp = imported_kind', 'wp', 'wp', '1.0', .false.)
    call check('shadowed dp is real32', 'integer, parameter :: dp = 4', &
        'dp', 'dp', '1.0_dp', .true.)
    call check('letter d is not exponent', 'integer, parameter :: width = 4', &
        'width', 'width', '1.0_width', .true.)
    call check('numeric kind', 'integer, parameter :: wp = 8', &
        '8', '8', '1.0_8', .true.)
    call check('double exponent', 'integer, parameter :: wp = 8', &
        'wp', 'wp', '1.0d0', .true.)
    call check('exponent-only named real literal', 'integer, parameter :: wp = 8', &
        'wp', 'wp', '1e-08_wp', .true.)
    call check('uppercase exponent-only real literal', 'integer, parameter :: wp = 8', &
        'wp', 'wp', '1E+02_wp', .true.)
    call check('exponent-only double literal', 'integer, parameter :: wp = 8', &
        'wp', 'wp', '1D-08', .true.)
    call check('default exponent-only real rejects real64 dummy', &
        'integer, parameter :: wp = 8', 'wp', 'wp', '1e-08', .false.)
    call check('integer suffix is not exponent', 'integer, parameter :: width = 4', &
        'width', 'width', '1_width', .false.)
    call check('named real64 rejects real32 literal', &
        'integer, parameter :: wp = 8', 'wp', 'wp', &
        '1.0', .false.)
    call check('named real32 rejects real64 literal', &
        'integer, parameter :: dp = 4', 'dp', 'dp', '1.0_8', .false.)
    call check('named real64 rejects declared real32 actual', &
        'integer, parameter :: wp = 8', '4', 'wp', &
        'x', .false.)
    call check('named real32 rejects declared real64 actual', &
        'integer, parameter :: width = 4', '8', 'width', 'x', .false.)

    ! Module USE association and host association must preserve the selector
    ! both in strict CALL validation and the public resolved-type queries.
    call compile_frontend_from_string('module kinds'//nl// &
        'use iso_fortran_env, only: real64'//nl//'implicit none'//nl// &
        'integer, parameter :: working = real64'//nl//'contains'//nl// &
        'real(working) function identity(x) result(y)'//nl// &
        'real(working), intent(in) :: x'//nl//'y=x'//nl// &
        'end function identity'//nl//'end module kinds'//nl// &
        'program p'//nl//'use kinds'//nl//'implicit none'//nl// &
        'real(working) :: actual'//nl//'actual=1.0_working'//nl// &
        'call take(1.0_working)'//nl//'call take(actual)'//nl//'contains'//nl// &
        'subroutine take(dummy)'//nl//'real(kind=working), intent(in) :: dummy'//nl// &
        'end subroutine take'//nl//'end program p', front, opts)
    call require_success('module and host associated kinds', .true.)
    found = 0
    do i = 1, front%arena%entry_count
        decl = query_declaration(front%arena, i)
        if (.not. front%arena%has_node_at(i)) cycle
        select type (node => front%arena%entries(i)%node)
        type is (declaration_node)
            select case (decl%name)
            case ('actual', 'dummy', 'x')
                typ = query_resolved_type(front%arena, i)
                if (.not. typ%found .or. typ%kind_value /= 8 .or. &
                    typ%storage_size_bits /= 64) error stop 'named kind metadata lost'
                found = found + 1
            end select
        type is (function_def_node)
            if (node%name /= 'identity') cycle
            typ = query_resolved_type(front%arena, i)
            if (.not. typ%found .or. typ%kind_value /= 8 .or. &
                typ%storage_size_bits /= 64) error stop 'named result kind metadata lost'
            found = found + 1
        end select
    end do
    if (found /= 4) error stop 'missing named-kind metadata test targets'
    call check_nested_function('8', .true.)
    call check_nested_function('4', .false.)
    call compile_frontend_from_string('program p'//nl// &
        'use iso_fortran_env, only: real64'//nl//'implicit none'//nl// &
        'integer, parameter :: wp = real64'//nl//'real(wp) :: x'//nl// &
        'x=erfc(1.0_wp)'//nl//'print *, erfc(x)'//nl//'end program p', front, opts)
    call require_success('ERFC is an intrinsic in the main program', .true.)
    found = 0
    do i = 1, front%arena%entry_count
        if (.not. front%arena%has_node_at(i)) cycle
        select type (node => front%arena%entries(i)%node)
        type is (call_or_subscript_node)
            if (node%name /= 'erfc') cycle
            if (.not. node%is_intrinsic) error stop 'ERFC intrinsic flag lost'
            typ = query_resolved_type(front%arena, i)
            if (.not. typ%found .or. typ%kind_value /= 8) &
                error stop 'ERFC argument kind not preserved'
            found = found + 1
        end select
    end do
    if (found /= 2) error stop 'missing ERFC metadata test targets'
    print *, 'PASS: scope-aware real kinds, exponent literals, ERFC, and mismatch rejection'
contains
    subroutine check(label, declarations, actual_kind, dummy_kind, actual, expected)
        character(*), intent(in) :: label, declarations, actual_kind, dummy_kind, actual
        logical, intent(in) :: expected
        call compile_frontend_from_string('program p'//nl//declarations//nl// &
            'real('//actual_kind//') :: x'//nl//'x=1'//nl// &
            'call take('//actual//')'//nl//'contains'//nl// &
            'subroutine take(y)'//nl//'real(kind='//dummy_kind//'), intent(in) :: y'//nl// &
            'end subroutine take'//nl//'end program p', front, opts)
        call require_success(label, expected)
    end subroutine check

    subroutine check_nested_function(result_kind, expected)
        character(*), intent(in) :: result_kind
        logical, intent(in) :: expected
        call compile_frontend_from_string('module m'//nl// &
            'use iso_fortran_env, only: real64'//nl//'implicit none'//nl// &
            'integer, parameter :: wp=real64'//nl//'contains'//nl// &
            'real('//result_kind//') function f(x)'//nl//'real(wp), intent(in) :: x'//nl// &
            'f=x'//nl//'end function'//nl//'subroutine sink(text,x)'//nl// &
            'character(len=*), intent(in) :: text'//nl//'real(wp), intent(in) :: x'//nl// &
            'end subroutine'//nl//'end module'//nl//'program p'//nl//'use m'//nl// &
            'implicit none'//nl//"call inner('hello')"//nl//'contains'//nl// &
            'subroutine inner(text)'//nl//'character(len=*), intent(in) :: text'//nl// &
            'call sink(text,f(1.0_wp))'//nl//'end subroutine'//nl//'end program', front, opts)
        call require_success('internal CHARACTER and nested typed function actual', expected)
    end subroutine check_nested_function

    subroutine require_success(label, expected)
        character(*), intent(in) :: label
        logical, intent(in) :: expected
        if (front%success() .eqv. expected) then
            if (.not. expected) then
                if (.not. allocated(front%error_msg)) error stop 'missing kind diagnostic'
                if (index(front%error_msg, 'Type mismatch in call') == 0) then
                    print *, label, front%error_msg
                    error stop 'wrong kind mismatch diagnostic'
                end if
            end if
            return
        end if
        print *, label
        if (allocated(front%error_msg)) print *, front%error_msg
        error stop 'strict named-kind frontend regression'
    end subroutine require_success
end program test_named_real_kind_frontend
