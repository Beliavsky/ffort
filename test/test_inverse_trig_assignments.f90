! SPDX-License-Identifier: MIT
! Regression for host-associated intrinsic temporaries corrupting assignment loops.
program test_inverse_trig_assignments
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir, only: program_t, diagnostic_t
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    type(program_t) :: p
    type(diagnostic_t) :: d
    character(*), parameter :: nl = new_line('a')
    character(5), parameter :: names(4) = [character(5) :: 'asin', 'atan', 'atan', 'atan2']
    character(5), parameter :: inputs(5) = [character(5) :: '-0.75', '-0.5', '0.0', '0.25', '0.75']
    character(4), parameter :: denoms(5) = [character(4) :: '1.0', '-1.0', '2.0', '-2.0', '4.0']
    character(:), allocatable :: source, name, suffix, decl, xs, ys, scalar, vector
    character(12) :: count_text
    integer :: family, rk, n, i, checks
    checks = 0
    do family = 1, 4
        name = trim(names(family))
        do rk = 4, 8, 4
            suffix = ''
            decl = 'real'
            if (rk == 8) then
                suffix = 'd0'
                decl = 'real(8)'
            end if
            do n = 1, 5
                write(count_text, '(i0)') n
                xs = '['
                ys = '['
                do i = 1, n
                    if (i > 1) then
                        xs = xs//','
                        ys = ys//','
                    end if
                    xs = xs//trim(inputs(i))//suffix
                    ys = ys//trim(denoms(i))//suffix
                end do
                xs = xs//']'
                ys = ys//']'
                scalar = name//'(x(i))'
                vector = name//'(x)'
                if (family >= 3) then
                    scalar = name//'(x(i),y(i))'
                    vector = name//'(x,y)'
                end if
                source = 'program p'//nl//'implicit none'//nl// &
                    decl//'::x('//trim(count_text)//'),y('//trim(count_text)// &
                    '),z('//trim(count_text)//'),reference('//trim(count_text)//')'//nl// &
                    'integer::i,j,sentinel'//nl//'j=43'//nl//'sentinel=17'//nl// &
                    'x='//xs//nl//'y='//ys//nl//'z=-99.0'//suffix//nl// &
                    'do i=1,'//trim(count_text)//nl//'reference(i)='//scalar//nl//'end do'//nl// &
                    'z='//vector//nl// &
                    "if(any(z/=reference)) error stop 'assignment skipped or changed values'"//nl// &
                    "if(j/=43.or.sentinel/=17) error stop 'independent sentinel changed'"//nl// &
                    'if(i/='//trim(count_text)//"+1) error stop 'loop index changed'"//nl//'end program'
                call parse_subset(source, p, d)
                call expect(d%code == 0, 'source parse')
                call verify_frontend(source, p, d)
                call expect(d%code == 0, 'frontend acceptance')
                ! The small first budget kills the original counter-corruption
                ! mutant quickly. It must still pass every value/sentinel check.
                call execute_program(p, d, max_steps=2000_int64)
                call expect(d%code == 0, 'bounded assignment execution')
                ! User acceptance is also checked with the unchanged default.
                call execute_program(p, d)
                call expect(d%code == 0, 'default-budget assignment execution')
            end do
        end do
    end do
    print '(a,i0)', 'PASS: inverse trigonometric assignment assertions: ', checks
contains
    subroutine expect(ok, label)
        logical, intent(in) :: ok
        character(*), intent(in) :: label
        checks = checks + 1
        if (ok) return
        print *, name, rk, n, label
        if (allocated(d%message)) print *, d%message
        error stop 'inverse trigonometric assignment regression'
    end subroutine
end program
