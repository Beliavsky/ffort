! SPDX-License-Identifier: MIT
! Direct FortFront producer regression; does not use the interpreter adapter.
program test_keyword_producers
    use fortfront_compiler
    use fortfront_ast, only: assignment_node, identifier_node
    use type_system_unified, only: TREAL, TINT
    implicit none
    character(*), parameter :: nl = new_line('a')
    type(compiler_frontend_options_t) :: opts
    type(compiler_frontend_result_t) :: front
    type(resolved_type_query_t) :: typ
    integer :: i, count, ordinary, rhs
    character(:), allocatable :: name

    opts%input_mode = INPUT_MODE_STANDARD
    opts%operating_mode = OPERATING_MODE_STRICT
    opts%standardize = .false.
    opts%run_semantics = .true.
    call compile_frontend_from_string('program p'//nl// &
        'implicit none'//nl//'real :: a(3), r'//nl//'integer :: n'//nl// &
        'a=2.0'//nl//'r=f(y=3, x=1.5)'//nl// &
        'r=sum(array=a)'//nl//'n=size(array=a, dim=1)'//nl// &
        'r=abs(a=-2.0)'//nl//'call sink(x=1.5)'//nl//'contains'//nl// &
        'real function f(x,y)'//nl//'real, intent(in) :: x'//nl// &
        'integer, intent(in) :: y'//nl//'f=x+y'//nl//'end function'//nl// &
        'subroutine sink(x)'//nl//'real, intent(in) :: x'//nl// &
        'end subroutine'//nl//'end program', front, opts)
    if (.not. front%success()) then
        if (allocated(front%error_msg)) print *, front%error_msg
        error stop 'keyword producer rejected valid source'
    end if
    count = 0
    ordinary = 0
    do i = 1, front%arena%entry_count
        if (.not. front%arena%has_node_at(i)) cycle
        select type (node => front%arena%entries(i)%node)
        type is (assignment_node)
            if (.not. node%is_keyword_argument) then
                ordinary = ordinary + 1
                cycle
            end if
            count = count + 1
            rhs = node%value_index
            select type (label => front%arena%entries(node%target_index)%node)
            type is (identifier_node)
                name = label%name
            class default
                error stop 'keyword label is not an identifier'
            end select
            typ = query_resolved_type(front%arena, rhs)
            if (.not. typ%found) error stop 'keyword RHS metadata missing'
            select case (name)
            case ('array')
                if (typ%type_kind /= TREAL .or. typ%rank /= 1) &
                    error stop 'array keyword RHS type or rank lost'
            case ('x', 'a')
                if (typ%type_kind /= TREAL .or. typ%rank /= 0) &
                    error stop 'real keyword RHS type or rank lost'
            case ('y', 'dim')
                if (typ%type_kind /= TINT .or. typ%rank /= 0) &
                    error stop 'integer keyword RHS type or rank lost'
            case default
                error stop 'unexpected keyword label'
            end select
        end select
    end do
    if (count /= 7) error stop 'function, intrinsic or CALL keyword wrapper missing'
    if (ordinary /= 6) error stop 'ordinary assignment incorrectly marked keyword'

    ! Marking keywords must not suppress strict checks on their actual values.
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'real :: r'//nl//'r=f(x=1)'//nl//'contains'//nl// &
        'real function f(x)'//nl//'real, intent(in) :: x'//nl// &
        'f=x'//nl//'end function'//nl//'end program', front, opts)
    if (front%success()) error stop 'keyword type mismatch was accepted'
    if (.not. allocated(front%error_msg)) error stop 'keyword diagnostic missing'
    if (index(front%error_msg, 'Type mismatch in call') == 0) then
        print *, front%error_msg
        error stop 'wrong keyword type mismatch diagnostic'
    end if
end program test_keyword_producers
