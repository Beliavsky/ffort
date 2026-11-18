! SPDX-License-Identifier: MIT
program test_character_scalar_binding
    use fortfront_compiler
    use fi_ir,only:program_t,diagnostic_t
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use semantic_strict_argument_type_checker_types,only:strict_types_match
    use type_system_unified,only:mono_type_t,create_mono_type,TCHAR,TARRAY
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(program_t)::p
    type(diagnostic_t)::d
    type(mono_type_t)::two,three,array_two,array_three
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call check('character','"abc"',.true.)
    call check('character(2)','"abc"',.true.)
    call check('character(*)','"abc"',.true.)
    call check('character','42',.false.)
    call check('character','[character(3)::"abc"]',.false.)
    call run_case('character','a')
    call run_case('character(2)','ab')
    call parse_subset('program test'//nl//'implicit none'//nl//'integer::a(2)'//nl// &
        'call f(a,"abc")'//nl//'if(any(a/=2)) error stop 1'//nl//'contains'//nl// &
        'elemental subroutine f(a,x)'//nl//'integer,intent(out)::a'//nl// &
        'character(2),intent(in)::x'//nl//'a=len(x)'//nl//'end subroutine'//nl// &
        'end program',p,d)
    call require_ok('elemental parse')
    call execute_program(p,d)
    call require_ok('elemental runtime')
    two=create_mono_type(TCHAR,char_size=2);three=create_mono_type(TCHAR,char_size=3)
    array_two=create_mono_type(TARRAY,args=[two]);array_three=create_mono_type(TARRAY,args=[three])
    if(strict_types_match(array_two,array_three)) error stop 'array length equality weakened'
    if(.not.strict_types_match(array_two,array_two)) error stop 'equal array lengths rejected'
    print '(a)','PASS: scalar CHARACTER prefix association and strict array length matching'
contains
    subroutine check(spec,actual,want)
        character(*),intent(in)::spec,actual
        logical,intent(in)::want
        call compile_frontend_from_string('program test'//nl//'call f('//actual//')'//nl// &
            'contains'//nl//'subroutine f(x)'//nl//spec//',intent(in)::x'//nl// &
            'end subroutine'//nl//'end program',front,opts)
        if(front%success().neqv.want) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'scalar CHARACTER producer acceptance differs'
        end if
    end subroutine
    subroutine run_case(spec,want)
        character(*),intent(in)::spec,want
        character(:),allocatable::source
        source='program test'//nl//'implicit none'//nl//'call f("abc")'//nl// &
            'contains'//nl//'subroutine f(x)'//nl//spec//',intent(in)::x'//nl// &
            'if(x/="'//want//'") error stop 1'//nl//'end subroutine'//nl//'end program'
        call parse_subset(source,p,d)
        call require_ok('parse')
        call verify_frontend(source,p,d)
        call require_ok('adapter')
        call execute_program(p,d)
        call require_ok('runtime')
    end subroutine
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'scalar CHARACTER association regression'
        end if
    end subroutine
end program
