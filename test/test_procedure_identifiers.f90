! SPDX-License-Identifier: MIT
program test_procedure_identifiers
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:subroutine_def_node,declaration_node
    use ast_nodes_data,only:parameter_declaration_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        "call check(procedure='ok')"//nl//'contains'//nl// &
        'subroutine check(procedure)'//nl//'character(*),intent(in)::procedure'//nl// &
        "if(procedure/='ok') error stop 1"//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,j,s,seen
    call parse_subset(source,p,d)
    call okay('parse')
    s=p%procedures(1)%args(1)
    if(p%symbols(s)%name/='procedure'.or..not.p%symbols(s)%is_dummy) &
        error stop 'dummy identity lost'
    call verify_frontend(source,p,d)
    call okay('adapter')
    call execute_program(p,d)
    call okay('runtime')
    p%symbols(s)%name='wrong'
    call verify_frontend(source,p,d)
    if(d%code==0) error stop 'forged dummy name passed adapter'
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success()) error stop 'producer rejected contextual dummy'
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(subroutine_def_node)
            if(n%name/='check') cycle
            if(.not.allocated(n%param_indices)) error stop 'dummy list missing'
            if(size(n%param_indices)/=1) error stop 'dummy list changed'
            j=n%param_indices(1)
            select type(a=>front%arena%entries(j)%node)
            type is(parameter_declaration_node)
                if(a%name/='procedure') error stop 'producer dummy name changed'
            class default
                error stop 'producer dummy node missing'
            end select
            seen=seen+1
        end select
    end do
    if(seen/=1) error stop 'producer procedure missing'
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'interface'//nl//'integer function f(x)'//nl//'integer,intent(in)::x'//nl// &
        'end function'//nl//'end interface'//nl//'procedure(f),pointer::cb'//nl//'end program',front,opts)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'genuine PROCEDURE declaration changed'
    end if
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(declaration_node)
            if(.not.allocated(n%var_name)) cycle
            if(n%var_name/='cb') cycle
            if(.not.n%is_pointer) error stop 'genuine PROCEDURE pointer attribute lost'
            if(.not.allocated(n%type_name)) error stop 'genuine PROCEDURE type missing'
            if(index(lower(n%type_name),'procedure')/=1) error stop 'genuine PROCEDURE type changed'
            seen=seen+1
        end select
    end do
    if(seen/=1) error stop 'genuine PROCEDURE declaration missing'
    print '(a)','PASS: contextual PROCEDURE dummy identity, adapter mutation and genuine declaration'
contains
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'contextual identifier check failed'
        end if
    end subroutine
end program
