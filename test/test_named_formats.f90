! SPDX-License-Identifier: MIT
program test_named_formats
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    use fortfront_compiler, only: compiler_frontend_result_t, compiler_frontend_options_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT
    use fortfront_ast, only: print_statement_node
    use ast_nodes_io, only: write_statement_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl// &
        'implicit none'//nl// &
        'character(*),parameter::fmt="(i0)"'//nl// &
        'character(8)::s'//nl// &
        'write(s,fmt)12'//nl// &
        'if(s/="12")error stop 1'//nl// &
        'print fmt,12'//nl// &
        'write(*,fmt)34'//nl// &
        'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::opts
    integer::i,k,s,wr,e,checks,prints,writes
    checks=0
    call parse_subset(source,p,d);call require(d%code==0,'source parse')
    call verify_frontend(source,p,d);call require(d%code==0,'independent adapter')
    call execute_program(p,d);call require(d%code==0,'internal and external execution')
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    call compile_frontend_from_string(source,front,opts)
    prints=0;writes=0
    do i=1,front%arena%size
        if(.not.allocated(front%arena%entries(i)%node))cycle
        select type(node=>front%arena%entries(i)%node)
        type is(print_statement_node)
            call require(allocated(node%format_spec),'producer PRINT format retained')
            call require(node%format_spec=='fmt','producer PRINT retains name, not folded value')
            prints=prints+1
        type is(write_statement_node)
            call require(allocated(node%format_spec),'producer WRITE format retained')
            call require(node%format_spec=='fmt','producer WRITE retains name, not folded value')
            call require(node%format_expr_index==0,'simple name is not executable format expression')
            writes=writes+1
        end select
    end do
    call require(prints==1.and.writes==2,'all producer output nodes inspected')
    wr=0;s=0
    do i=1,p%nc
        if(p%code(i)%op==op_write_internal)wr=i
    end do
    do i=1,p%ns
        if(trim(p%symbols(i)%name)=='fmt')s=i
    end do
    call require(wr>0.and.s>0,'format symbol and internal WRITE found')
    e=p%symbols(s)%initializer_expr
    call require(e>0,'initializer found')
    do k=1,14
        q=p
        select case(k)
        case(1);q%code(wr)%format='(a)'
        case(2);q%code(wr)%format='(i0) '
        case(3);q%symbols(s)%is_parameter=.false.
        case(4);q%symbols(s)%parameter_ready=.false.
        case(5);q%symbols(s)%typ=ty_integer
        case(6);q%symbols(s)%rank=1
        case(7);q%symbols(s)%character_len=5
        case(8);q%symbols(s)%constant_value%s='(i0) '
        case(9);q%symbols(s)%constant_value%tag=ty_integer
        case(10);deallocate(q%symbols(s)%constant_value%s)
        case(11);q%symbols(s)%name='other'
        case(12);deallocate(q%code(wr)%format)
        case(13)
            q%expressions(e)%value%s='(a)';q%symbols(s)%constant_value%s='(a)';q%code(wr)%format='(a)'
        case(14)
            q%symbols(s)%constant_value%s='(a)';q%code(wr)%format='(a)'
        end select
        d=diagnostic_t();call verify_frontend(source,q,d)
        call require(d%code/=0,'source-bound format/declaration/initializer mutation rejected')
    end do
    do k=1,5
        q=p
        select case(k)
        case(1);q%code(wr)%format='(*(i0),a)'
        case(2);q%code(wr)%format='(*("prefix"))'
        case(3);q%code(wr)%format='(g0.5)'
        case(4);q%code(wr)%format='(a)'
        case(5);q%code(wr)%format='(i0'
        end select
        d=diagnostic_t();call execute_program(q,d)
        call require(d%code==2,'runtime revalidates frozen named format')
    end do
    print *,'PASS: named parameter format native assertions:',checks
contains
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *,label
            if(allocated(d%message))print *,d%message
            error stop 'named format assertion failed'
        end if
        checks=checks+1
    end subroutine
end program
