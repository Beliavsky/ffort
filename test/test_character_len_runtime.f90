! SPDX-License-Identifier: MIT
program test_character_len_runtime
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    integer::which,j,c,q
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program test'//nl//'implicit none'//nl// &
        'integer::n'//nl//'n=len("abc")'//nl//'if(n/=3) error stop 1'//nl//'end program'
    do which=1,9
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'LEN baseline parse failed'
        c=0;q=0
        do j=1,p%ne
            if(p%expressions(j)%typ==ty_character) c=j
            if(p%expressions(j)%op=='len') q=j
        end do
        if(min(c,q)==0) error stop 'LEN nodes missing'
        select case(which)
        case(2);p%expressions(c)%character_len=4
        case(3);deallocate(p%expressions(c)%value%s)
        case(4);p%expressions(c)%value%tag=ty_integer
        case(5);p%expressions(q)%args=[c,c]
        case(6);deallocate(p%expressions(q)%args)
        case(7);p%expressions(q)%args(1)=0
        case(8);p%expressions(q)%args(1)=q
        case(9);p%expressions(q)%rank=1
        end select
        call execute_program(p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'LEN runtime baseline failed'
            end if
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'LEN corrupt runtime accepted'
        end if
    end do
    print '(a)','PASS: LEN descriptors and eight direct-runtime corruptions'
end program
