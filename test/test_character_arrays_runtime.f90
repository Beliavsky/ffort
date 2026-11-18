! SPDX-License-Identifier: MIT
program test_character_arrays_runtime
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_runtime,only:execute_program,evaluate_constant_array
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t),allocatable::values(:)
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='implicit none'//nl// &
        'character(3)::a(2)=[character(2)::"a","bcd"]'//nl// &
        'if(a(1)//":"/="a  :") error stop 1'//nl// &
        'if(a(2)//":"/="bc :") error stop 2'//nl// &
        'a(1)="wxyz"'//nl//'if(a(1)/="wxy") error stop 3'//nl// &
        'a=a(2:1:-1)'//nl//'if(a(2)/="wxy") error stop 4'//nl// &
        'a="q"'//nl//'if(a(2)//":"/="q  :") error stop 5'//nl//'end'
    integer::which,j,c
    do which=1,11
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'character runtime baseline parse'
        c=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_constructor) c=j
        end do
        select case(which)
        case(2);p%expressions(c)%character_len=-1
        case(3);p%expressions(c)%character_len=65537
        case(4);p%expressions(c)%op='integer'
        case(5);p%expressions(c)%op=''
        case(6);p%expressions(c)%args(1)=0
        case(7);p%expressions(c)%args(1)=c
        case(8);p%symbols(1)%character_len=-1
        case(9);p%symbols(1)%character_len=65537
        case(10);p%expressions(c)%rank=2
        case(11);deallocate(p%expressions(c)%args)
        end select
        call execute_program(p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'character runtime baseline failed'
            end if
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'corrupt CHARACTER array IR accepted'
        end if
    end do
    call parse_subset(source,p,d)
    call evaluate_constant_array(p,p%symbols(1)%initializer_expr,values,d,ty_character)
    if(d%code/=0.or.size(values)/=2) error stop 'character constant evaluation failed'
    if(len(values(1)%s)/=2.or.len(values(2)%s)/=2) error stop 'constructor LEN lost'
    if(values(1)%s/='a '.or.values(2)%s/='bc') error stop 'constructor padding/truncation differs'
    print '(a)','PASS: CHARACTER padding/overlap, 10 runtime corruptions and constructor constant evaluation'
end program
