! SPDX-License-Identifier: MIT
program test_imported_parameter_array_producer
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant
    use fortfront_compiler, only: compiler_frontend_result_t, compiler_frontend_options_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::header='module m'//nl//'implicit none'//nl
    character(*),parameter::array_decl='integer(8),parameter::a(1)=[9007199254740993_8]'//nl
    character(*),parameter::scalar_decl='integer(8),parameter::a=9007199254740993_8'//nl
    character(*),parameter::tail='implicit none'//nl//'print *,a(1)'//nl//'end program'//nl
    character(*),parameter::main='end module'//nl//'program p'//nl
    character(*),parameter::call_body='contains'//nl//'function f(x) result(r)'//nl// &
        'integer(8),intent(in)::x'//nl//'integer(8)::r'//nl//'r=x'//nl//'end function'//nl
    character(*),parameter::record_body='type::box'//nl//'integer(8)::v'//nl//'end type'//nl
    call check(header//array_decl//main//'use m'//nl//tail,.true.,'direct import')
    call check(header//array_decl//main//'use m,only:a'//nl//tail,.true.,'ONLY import')
    call check(header//'private'//nl//'public::a'//nl//array_decl//main//'use m'//nl//tail, &
        .true.,'explicit public import')
    call check(header//array_decl//main//'use m'//nl//'implicit none'//nl// &
        'print *,a(1)-9007199254740993_8'//nl//'end program'//nl,.true.,'arithmetic element')
    call check(header//array_decl//call_body//main//'use m'//nl//'implicit none'//nl// &
        'print *,f(a(1))'//nl//'end program'//nl,.true.,'element actual')
    call check(header//array_decl//record_body//main//'use m'//nl//'implicit none'//nl// &
        'type(box)::x'//nl//'x=box(a(1))'//nl//'print *,x%v'//nl//'end program'//nl, &
        .true.,'constructor element')
    call check(header//'private'//nl//array_decl//main//'use m'//nl//tail,.false.,'private array')
    call check(header//array_decl//'integer,parameter::b=1'//nl//main//'use m,only:b'//nl//tail, &
        .false.,'array omitted from ONLY')
    call check(header//array_decl//main//'use m,only:'//nl//tail,.false.,'empty ONLY')
    call check(header//scalar_decl//main//'use m'//nl//tail,.false.,'scalar is not array')
    call check('program p'//nl//'implicit none'//nl//'print *,missing(1)'//nl//'end program'//nl, &
        .false.,'undeclared function remains rejected')
contains
    subroutine check(source,wanted,label)
        character(*),intent(in)::source,label
        logical,intent(in)::wanted
        type(compiler_frontend_result_t)::front
        type(compiler_frontend_options_t)::opts
        type(program_t)::p
        type(diagnostic_t)::d
        type(value_t)::value
        integer::e,j
        integer(int64)::expected
        opts%input_mode=INPUT_MODE_STANDARD
        opts%operating_mode=OPERATING_MODE_STRICT
        opts%standardize=.false.
        opts%run_semantics=.true.
        call compile_frontend_from_string(source,front,opts)
        if(front%success().neqv.wanted) then
            print *,label
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'imported array producer regression'
        end if
        if(.not.wanted) return
        call parse_subset(source,p,d)
        if(d%code==0) call verify_frontend(source,p,d)
        if(d%code/=0) then
            print *,label
            if(allocated(d%message)) print *,d%message
            error stop 'imported array adapter regression'
        end if
        ! Compare exact INTEGER values, never floating-point approximations.
        expected=9007199254740993_int64
        if(label=='arithmetic element') expected=0_int64
        e=p%code(p%nc)%items(1)
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_record) e=j
        end do
        if(p%expressions(e)%kind==ex_user_call) e=p%expressions(e)%args(1)
        call evaluate_constant(p,e,value,d)
        if(d%code/=0) then
            print *,label,d%message
            error stop 'imported array runtime evaluation failed'
        end if
        if(is_derived_type(value%tag)) then
            if(.not.allocated(value%record)) error stop 'record payload missing'
            if(.not.allocated(value%record%components)) error stop 'record component missing'
            if(value%record%components(1)%i/=expected) error stop 'record element INTEGER precision lost'
        else
            if(value%tag/=ty_integer.or.value%i/=expected) error stop 'imported INTEGER element precision lost'
        end if
    end subroutine
end program
