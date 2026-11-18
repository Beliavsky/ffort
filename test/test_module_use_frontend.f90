! SPDX-License-Identifier: MIT
program test_module_use_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fortfront_compiler, only: compiler_frontend_result_t, compiler_frontend_options_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT
    use ast_nodes_data, only: declaration_node, module_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module first'//nl//'implicit none'//nl// &
        'integer,parameter::width=4,wide=8,alias=wide'//nl//'end module'//nl// &
        'module second'//nl//'use first,only:width,wide,alias'//nl//'implicit none'//nl// &
        'private'//nl//'public::answer,probe'//nl//'integer,parameter::answer=alias+width'//nl// &
        'contains'//nl//'integer function probe(x) result(y)'//nl// &
        'integer,intent(in)::x'//nl//'y=x+answer'//nl//'end function'//nl//'end module'//nl// &
        'program main'//nl//'use second,only:answer,probe'//nl//'implicit none'//nl// &
        'print *,answer,probe(3)'//nl//'end program'//nl
    type(program_t)::p,bad
    type(diagnostic_t)::d
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::opts
    integer::j,decls
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'module USE producer rejected source'
    end if
    decls=0
    do j=1,front%arena%size
        if(.not.front%arena%has_node_at(j)) cycle
        select type(node=>front%arena%entries(j)%node)
        type is(declaration_node)
            if(node%is_parameter) decls=decls+1
        end select
    end do
    if(decls/=4) error stop 'producer dropped a chained PARAMETER declarator'
    call parse_subset(source,p,d)
    if(d%code==0) call verify_frontend(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'module USE baseline rejected'
    end if
    if(p%nu/=2.or.p%use_scopes(1)/=-2.or.p%use_scopes(2)/=0) error stop 'USE ownership not retained'
    bad=p;bad%use_scopes(1)=0;call reject(bad,'changed module USE owner')
    bad=p;bad%use_scopes(2)=-2;call reject(bad,'changed main USE owner')
    bad=p;bad%use_scopes(1)=1;call reject(bad,'procedure USE owner')
    bad=p;bad%use_scopes(1)=-3;call reject(bad,'invalid USE owner')
    bad=p;bad%uses(1)=2;call reject(bad,'self USE binding')
    bad=p;bad%use_lines(1)=bad%use_lines(1)+1;call reject(bad,'USE source location')
    bad=p;bad%only_names(1,1)='answer';call reject(bad,'changed ONLY name')
    bad=p;bad%use_only(1)=.false.;call reject(bad,'changed ONLY flag')
    bad=p;bad%symbols(3)%constant_value%i=4;call reject(bad,'chained constant cache')
    print *,'module USE frontend: producer + baseline + 9 mutations passed'
contains
    subroutine reject(bad,label)
        type(program_t),intent(in)::bad
        character(*),intent(in)::label
        type(diagnostic_t)::d
        call verify_frontend(source,bad,d)
        if(d%code==0) then
            print *,label
            error stop 'module USE mutation accepted'
        end if
    end subroutine
end program
