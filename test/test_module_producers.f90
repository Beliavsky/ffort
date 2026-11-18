! SPDX-License-Identifier: MIT
! Direct producer regressions: no interpreter adapter or source rewriting.
program test_module_producers
    use fortfront_compiler
    implicit none
    character(*), parameter :: nl = new_line('a')
    type(compiler_frontend_options_t) :: opts
    character(*), parameter :: array_element_actual = &
        'module m'//nl// &
        ''//nl// &
        'contains'//nl// &
        'function twice(x) result(y)'//nl// &
        'real, intent(in) :: x'//nl// &
        'real :: y'//nl// &
        'y=2*x'//nl// &
        'end function twice'//nl// &
        'end module m'//nl// &
        'program main'//nl// &
        'use m'//nl// &
        'implicit none'//nl// &
        'real :: a(-1:1)'//nl// &
        'a=2.5'//nl// &
        'a(0)=3.0'//nl// &
        'print *, twice(a(-1)),twice(a(0)),a'//nl// &
        'end program main'//nl
    character(*), parameter :: semicolon_scopes = &
        'module m; contains; function f(x) result(y)'//nl// &
        'integer,intent(in) :: x; integer :: y; y=x+1'//nl// &
        'end function f; function g(x) result(y)'//nl// &
        'integer,intent(in) :: x; integer :: y; y=f(x)*2'//nl// &
        'end function g; end module m'//nl// &
        'program main; use m; integer :: x,y; x=7; y=8'//nl// &
        'print *, f(2),g(2),x,y; end program main'//nl
    character(*), parameter :: semicolon_string = &
        'module m; contains; function f(x) result(y)'//nl// &
        'integer,intent(in) :: x; integer :: y; y=x+1'//nl// &
        'end function f; function g(x) result(y)'//nl// &
        'integer,intent(in) :: x; integer :: y; y=f(x)*2'//nl// &
        'end function g; end module m'//nl// &
        'program main; use m; integer :: x,y; x=7; y=8'//nl// &
        'print *, "a;b",f(2),g(2),x,y; end program main'//nl
    character(*), parameter :: consecutive_semicolons = &
        'module m; contains; function f(x) result(y)'//nl// &
        'integer,intent(in) :: x; integer :: y;;; y=x+1'//nl// &
        'end function f; function g(x) result(y)'//nl// &
        'integer,intent(in) :: x; integer :: y;;; y=f(x)*2'//nl// &
        'end function g; end module m'//nl// &
        'program main; use m; integer :: x,y; x=7; y=8'//nl// &
        'print *, f(2),g(2),x,y; end program main'//nl
    character(*), parameter :: wrong_integer_element = &
        'module m'//nl// &
        ''//nl// &
        'contains'//nl// &
        'function twice(x) result(y)'//nl// &
        'real, intent(in) :: x'//nl// &
        'real :: y'//nl// &
        'y=2*x'//nl// &
        'end function twice'//nl// &
        'end module m'//nl// &
        'program main'//nl// &
        'use m'//nl// &
        'implicit none'//nl// &
        'integer :: a(-1:1)'//nl// &
        'a=2'//nl// &
        'a(0)=3'//nl// &
        'print *, twice(a(-1)),twice(a(0)),a'//nl// &
        'end program main'//nl
    character(*), parameter :: wrong_real_element = &
        'module m'//nl// &
        ''//nl// &
        'contains'//nl// &
        'function twice(x) result(y)'//nl// &
        'integer, intent(in) :: x'//nl// &
        'real :: y'//nl// &
        'y=2*x'//nl// &
        'end function twice'//nl// &
        'end module m'//nl// &
        'program main'//nl// &
        'use m'//nl// &
        'implicit none'//nl// &
        'real :: a(-1:1)'//nl// &
        'a=2.5'//nl// &
        'a(0)=3.0'//nl// &
        'print *, twice(a(-1)),twice(a(0)),a'//nl// &
        'end program main'//nl
    character(*), parameter :: bad_trailing_tokens = &
        'module m; contains; function f(x) result(y)'//nl// &
        'integer,intent(in) :: x junk; integer :: y; y=x+1'//nl// &
        'end function f; function g(x) result(y)'//nl// &
        'integer,intent(in) :: x junk; integer :: y; y=f(x)*2'//nl// &
        'end function g; end module m'//nl// &
        'program main; use m; integer :: x,y; x=7; y=8'//nl// &
        'print *, f(2),g(2),x,y; end program main'//nl

    opts%input_mode = INPUT_MODE_STANDARD
    opts%operating_mode = OPERATING_MODE_STRICT
    opts%standardize = .false.
    opts%run_semantics = .true.
    call check('array_element_actual', array_element_actual, &
        '', '')
    call check('semicolon_scopes', semicolon_scopes, &
        '', '')
    call check('semicolon_string', semicolon_string, &
        '', '')
    call check('consecutive_semicolons', consecutive_semicolons, &
        '', '')
    call check('wrong_integer_element', wrong_integer_element, &
        'actual argument ''x'' is integer', 'dummy expects real')
    call check('wrong_real_element', wrong_real_element, &
        'actual argument ''x'' is real', 'dummy expects integer')
    call check('bad_trailing_tokens', bad_trailing_tokens, &
        'Syntax error: unexpected token after statement', '')
    print *, 'module producer regressions: 7 passed'
contains
    subroutine check(label, source, expected_error, second_error)
        character(*), intent(in) :: label, source, expected_error, second_error
        type(compiler_frontend_result_t) :: result
        call compile_frontend_from_string(source, result, opts)
        if (len(expected_error) == 0) then
            if (.not. result%success()) then
                print *, 'Unexpected rejection: ', label
                if (allocated(result%error_msg)) print *, result%error_msg
                error stop 'module producer positive regression'
            end if
        else
            if (result%success()) then
                print *, 'Unexpected acceptance: ', label
                error stop 'module producer negative regression'
            end if
            if (.not. allocated(result%error_msg)) then
                print *, 'Missing diagnostic: ', label
                error stop 'module producer diagnostic regression'
            end if
            if (index(result%error_msg, expected_error) == 0 .or. &
                index(result%error_msg, second_error) == 0) then
                print *, 'Wrong diagnostic: ', label
                print *, result%error_msg
                error stop 'module producer diagnostic regression'
            end if
        end if
    end subroutine check
end program test_module_producers
