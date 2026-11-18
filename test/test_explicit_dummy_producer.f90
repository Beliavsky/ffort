! SPDX-License-Identifier: MIT
program test_explicit_dummy_producer
    use fortfront_compiler
    use ast_nodes_data,only:declaration_node
    use semantic_strict_argument_type_checker_types,only:strict_dummy_type
    use type_system_unified,only:mono_type_t
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(mono_type_t)::typ
    integer::checks,i,j,found
    character(16)::specs(5)=[character(16)::'character(2)','character(len=2)','character(0)','character','character(*)']
    integer::lengths(5)=[2,2,0,1,-1]
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    checks=0
    do j=1,5
        call compile_frontend_from_string('module m'//nl//'implicit none'//nl//'contains'//nl// &
            'subroutine work(x,n)'//nl//'integer,intent(in)::n'//nl// &
            trim(specs(j))//',intent(out)::x(n)'//nl//'x="a"'//nl//'end subroutine'//nl//'end module',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 'explicit dummy producer rejected'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                if(.not.allocated(node%var_name))cycle
                if(node%var_name/='x')cycle
                typ=strict_dummy_type(front%arena,i)
                call typ%sync_from_arena()
                if(typ%kind/=TARRAY.or..not.typ%has_args())error stop 'explicit dummy rank lost'
                typ=typ%get_arg(1)
                call typ%sync_from_arena()
                if(typ%kind/=TCHAR.or.typ%size/=lengths(j))error stop 'explicit dummy CHARACTER length lost'
                found=found+1
            end select
        end do
        if(found/=1)error stop 'explicit dummy declaration absent'
        checks=checks+1
    end do
    call compile_frontend_from_string('program main'//nl//'implicit none'//nl// &
        'character(2)::a(3)'//nl//'call work(a,2)'//nl//'contains'//nl// &
        'subroutine work(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(2),intent(out)::x(n)'//nl//'x="ok"'//nl// &
        'end subroutine'//nl//'end program',front,opts)
    if(.not.front%success())error stop 'matching declared actual/dummy lengths rejected'
    checks=checks+1
    call compile_frontend_from_string('program main'//nl//'implicit none'//nl// &
        'character(3)::a(3)'//nl//'call work(a,2)'//nl//'contains'//nl// &
        'subroutine work(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(2),intent(out)::x(n)'//nl//'x="ok"'//nl// &
        'end subroutine'//nl//'end program',front,opts)
    if(front%success())error stop 'known mismatched array lengths accepted'
    checks=checks+1
    call compile_frontend_from_string('module m'//nl//'implicit none'//nl//'contains'//nl// &
        'subroutine relay(y,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(*),intent(inout)::y(:)'//nl//'call work(y,n)'//nl//'end subroutine'//nl// &
        'subroutine work(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(2),intent(out)::x(n)'//nl//'x="ok"'//nl// &
        'end subroutine'//nl//'end module',front,opts)
    if(.not.front%success())error stop 'unresolved actual length incorrectly rejected'
    checks=checks+1
    print *, 'PASS: explicit CHARACTER dummy independent producer lengths:',checks
end program
