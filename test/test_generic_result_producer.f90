! SPDX-License-Identifier: MIT
program test_generic_result_producer
    use fi_ir, only: program_t,diagnostic_t
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fortfront_compiler, only: compiler_frontend_result_t,compiler_frontend_options_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT, &
        query_resolved_type,resolved_type_query_t,TREAL,TINT
    use fortfront_ast, only: call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module operations'//nl//'implicit none'//nl// &
        'interface twice'//nl//'module procedure twice_i,twice_r'//nl//'end interface'//nl// &
        'contains'//nl//'elemental integer function twice_i(x) result(y)'//nl// &
        'integer,intent(in)::x'//nl//'y=2*x'//nl//'end function'//nl// &
        'elemental real(kind=8) function twice_r(x) result(y)'//nl// &
        'real(kind=8),intent(in)::x'//nl//'y=2*x'//nl//'end function'//nl// &
        'end module'//nl//'program main'//nl//'use operations,only:twice'//nl// &
        'implicit none'//nl//'real(kind=8)::x(3)=[1d0,2d0,3d0]'//nl// &
        'integer::a(3)=[1,2,3]'//nl//'print *,twice(x**2),twice(a+1),twice(x=3d0)'//nl// &
        'end program'//nl
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::options
    type(resolved_type_query_t)::q
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,n,expected_type(3),expected_kind(3),expected_rank(3)
    expected_type=[TREAL,TINT,TREAL];expected_kind=[8,4,8];expected_rank=[1,1,0]
    options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
    options%standardize=.false.;options%run_semantics=.true.
    call compile_frontend_from_string(source,front,options)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'generic result producer compilation failed'
    end if
    n=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if(.not.allocated(node%name)) cycle
            if(node%name/='twice') cycle
            n=n+1
            if(n>3) error stop 'extra generic call'
            q=query_resolved_type(front%arena,i)
            if(.not.q%found.or.q%type_kind/=expected_type(n).or.q%kind_value/=expected_kind(n).or. &
               q%rank/=expected_rank(n)) then
                print *,n,q%found,q%type_kind,q%kind_value,q%rank
                error stop 'generic result type/kind/rank metadata differs'
            end if
        end select
    end do
    if(n/=3) error stop 'missing generic result query'
    call parse_subset(source,p,d)
    call verify_frontend(source,p,d)
    if(d%code/=0) then
        if(allocated(d%message)) print *,d%message
        error stop 'generic REAL64 array expression adapter failed'
    end if
    print *,'generic result producer: three exact occurrence queries and adapter passed'
end program
