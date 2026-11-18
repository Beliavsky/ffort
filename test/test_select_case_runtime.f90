! SPDX-License-Identifier: MIT
! Runtime defensive validation after a separately parsed baseline.
program test_select_case_runtime
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_runtime,only:execute_program,evaluate_constant_array
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t),allocatable::values(:)
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer,parameter::a(3)=[1,2,3]'//nl//'integer::r'//nl// &
        'r=0'//nl//'select case(a(2))'//nl//'case default'//nl//'r=90'//nl// &
        'case(1)'//nl//'r=91'//nl//'case(2:3)'//nl//'r=7'//nl//'end select'//nl// &
        'if(r/=7) error stop 1'//nl//'end program'
    integer::which,j,s,c,e
    do which=1,15
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'baseline parse'
        s=0;c=0
        do j=1,p%nc
            if(p%code(j)%op==op_select) s=j
            if(p%code(j)%op==op_case) c=j
        end do
        e=p%code(s)%a
        select case(which)
        case(2);p%code(s)%a=0
        case(3);p%code(s)%target=s
        case(4);p%code(s)%target=p%nc+2
        case(5);p%code(s+1)%target=s+1
        case(6);p%code(s+1)%a=0
        case(7);p%code(s+1)%op=op_assign
        case(8);deallocate(p%code(c)%items)
        case(9);p%code(c)%items=[p%code(c)%items,1]
        case(10);p%code(c)%items=[0,0]
        case(11);p%code(c)%items=[p%ne+1,p%ne+1]
        case(12);p%symbols(1)%parameter_ready=.false.
        case(13);deallocate(p%symbols(1)%constant_values)
        case(14);p%symbols(1)%constant_values=p%symbols(1)%constant_values(:1)
        case(15);p%symbols(1)%constant_values(2)%tag=ty_real
        end select
        call execute_program(p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'baseline runtime'
            end if
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'malformed select/parameter IR accepted'
        end if
    end do
    call parse_subset(source,p,d)
    call evaluate_constant_array(p,p%symbols(1)%initializer_expr,values,d,ty_integer)
    if(d%code/=0) error stop 'constant array evaluation failed'
    if(size(values)/=3) error stop 'wrong constant extent'
    if(any(values%i/=[1,2,3])) error stop 'wrong constant array values'
    print '(a)','PASS: SELECT runtime baseline, 14 corruptions and constant array evaluation'
end program
