! SPDX-License-Identifier: MIT
program test_generic_producers
    use fortfront_compiler, only: compiler_frontend_result_t, compiler_frontend_options_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::head='module m'//nl//'implicit none'//nl
    character(*),parameter::definitions= &
        'interface twice'//nl//'module procedure times_two'//nl//'end interface'//nl// &
        'interface change'//nl//'module procedure change_int'//nl//'end interface'//nl// &
        'contains'//nl//'integer function times_two(x) result(r)'//nl// &
        'integer,intent(in)::x'//nl//'r=2*x'//nl//'end function'//nl// &
        'subroutine change_int(x)'//nl//'integer,intent(inout)::x'//nl// &
        'x=3*x'//nl//'end subroutine'//nl//'end module'//nl//'program test'//nl
    character(*),parameter::tail= &
        'implicit none'//nl//'integer::x=3'//nl//'call change(x)'//nl// &
        'print *,twice(x)'//nl//'end program'//nl
    call check(head//definitions//'use m'//nl//tail,.true.,'plain USE')
    call check(head//definitions//'use m,only:twice,change'//nl//tail,.true.,'ONLY')
    call check(head//'private'//nl//'public::twice,change'//nl//definitions// &
        'use m,only:twice,change'//nl//tail,.true.,'private specifics')
    call check(head//'private'//nl//definitions//'use m'//nl//tail,.false.,'private generic')
    call check(head//definitions//'use m,only:times_two'//nl//tail,.false.,'ONLY exclusion')
    call check(head//definitions//tail,.false.,'module not imported')
    call check(head//definitions//'use m,only:'//nl//tail,.false.,'empty ONLY')
    print *,'generic producer: 7 cases passed'
contains
    subroutine check(source,wanted,label)
        character(*),intent(in)::source,label
        logical,intent(in)::wanted
        type(compiler_frontend_result_t)::front
        type(compiler_frontend_options_t)::options
        options%input_mode=INPUT_MODE_STANDARD
        options%operating_mode=OPERATING_MODE_STRICT
        options%standardize=.false.
        options%run_semantics=.true.
        call compile_frontend_from_string(source,front,options)
        if(front%success().neqv.wanted) then
            print *,label
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'generic producer contract failed'
        end if
    end subroutine
end program
