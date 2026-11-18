! SPDX-License-Identifier: MIT
program test_control_flow
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer(8)::i,j,n'//nl//'n=0'//nl//'outer: do i=1,3'//nl// &
        'inner: do j=1,4'//nl//'if(j==1) then'//nl//'n=n+1'//nl// &
        'else if(j==2) then'//nl//'n=n+10'//nl//'cycle outer'//nl// &
        'else if(j==3) then'//nl//'exit inner'//nl//'else'//nl//'exit outer'//nl// &
        'end if'//nl//'end do inner'//nl//'end do outer'//nl// &
        'if(n/=33.or.i/=4.or.j/=2) error stop 1'//nl//'i=9'//nl//'j=8'//nl//'end program'
    integer::which,j,outer,inner,cy,ex,br,next
    ! Adapter validation includes all ELSE IF statements and named target resolution.
    do which=1,13
        call baseline()
        select case(which)
        case(2);p%code(cy)%construct_name='missing'
        case(3);p%code(cy)%a=inner
        case(4);p%code(cy)%target=p%nc+1
        case(5);p%code(ex)%a=outer
        case(6);p%code(ex)%target=inner+1
        case(7);p%code(outer)%construct_name='wrong'
        case(8);p%code(br)%target=br
        case(9);p%code(p%code(br)%target)%a=p%code(br)%a
        case(10);p%code(cy)%op=op_exit
        case(11);p%code(ex)%op=op_cycle
        case(12);p%code(inner)%target=p%nc+1
        case(13);p%code(cy)%a=0
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'control adapter baseline failed'
            end if
        else if(d%code==0) then
            print *,which
            error stop 'control adapter admitted corruption'
        end if
    end do
    do which=1,15
        call baseline()
        next=p%code(outer)%target-1
        select case(which)
        case(2);p%code(cy)%a=0
        case(3);p%code(cy)%a=p%nc+1
        case(4);p%code(cy)%a=outer+1
        case(5);p%code(cy)%target=p%nc+2
        case(6);p%code(cy)%target=outer+1
        case(7);p%code(outer)%target=p%nc+2
        case(8);p%code(outer)%target=outer
        case(9);p%code(next)%a=inner
        case(10);p%code(next)%target=inner+1
        case(11);p%code(outer)%a=0
        case(12);p%code(outer)%b=p%ne+1
        case(13);p%symbols(p%code(outer)%symbol)%real_kind=16
        case(14);p%expressions(p%code(outer)%a)%rank=1
        case(15);p%code(outer)%c=p%ne+1
        end select
        call execute_program(p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'control runtime baseline failed'
            end if
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'control runtime admitted corruption'
        end if
    end do
    print '(a)','PASS: control-flow adapter/runtime baselines and 26 malformed-IR rejections'
contains
    subroutine baseline()
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'control baseline parse'
        outer=0;inner=0;cy=0;ex=0;br=0
        do j=1,p%nc
            if(p%code(j)%op==op_do) then
                if(outer==0) then
                    outer=j
                else
                    inner=j
                end if
            end if
            if(p%code(j)%op==op_cycle) cy=j
            if(p%code(j)%op==op_exit.and.ex==0) ex=j
            if(p%code(j)%op==op_branch.and.br==0) br=j
        end do
    end subroutine
end program
