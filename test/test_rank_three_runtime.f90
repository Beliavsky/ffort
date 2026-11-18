! SPDX-License-Identifier: MIT
! Exercise public runtime IR independently of the source adapter.
program test_rank_three_runtime
    use, intrinsic :: iso_fortran_env, only: int64, output_unit, error_unit
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'integer :: aa(2,2,2)'//nl// &
        'aa=7'//nl//'aa(1,1,2)=9'//nl//'print *,123,aa(1,1,2),aa'//nl//'end program p'
    character(*),parameter::random_source='program p'//nl//'real(8) :: aa(2,2,2)'//nl// &
        'integer :: i,j,k'//nl//'call random_number(aa)'//nl// &
        'do k=1,2'//nl//'do j=1,2'//nl//'do i=1,2'//nl// &
        'if (aa(i,j,k)<0.0d0.or.aa(i,j,k)>=1.0d0) error stop 1'//nl// &
        'end do'//nl//'end do'//nl//'end do'//nl// &
        'print *,aa'//nl//'end program p'
    integer::which,e,pc,ios,j
    integer(int64)::state,wanted
    character(4096)::record,first_record
    ! Capture the public PRINT stream so failed records must remain atomic.
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    do which=1,11
        call parse_subset(source,p,d)
        call require_parse()
        select case(which)
        case(1:3)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_element) cycle
                select case(which)
                case(1)
                    p%expressions(p%expressions(e)%third)%value%i=3_int64
                case(2)
                    p%expressions(e)%third=0
                case(3)
                    p%expressions(e)%third=e
                end select
                exit
            end do
        case(4:7)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_variable.or.p%expressions(e)%rank/=3) cycle
                select case(which)
                case(4)
                    p%expressions(e)%dims(3)=3_int64
                case(5)
                    p%expressions(e)%dims(3)=-2_int64
                case(6)
                    p%expressions(e)%third=p%symbols(1)%upper_expr3
                case(7)
                    p%expressions(e)%left3=p%symbols(1)%upper_expr3
                end select
                exit
            end do
        case(8:10)
            do pc=1,p%nc
                if(p%code(pc)%op/=op_assign.or.p%code(pc)%b==0) cycle
                select case(which)
                case(8)
                    p%code(pc)%third=0
                case(9)
                    p%code(pc)%third=p%ne+1
                case(10)
                    p%expressions(p%code(pc)%third)%value%i=3_int64
                end select
                exit
            end do
        case(11)
            p%symbols(1)%upper_bound3=2147483647_int64
        end select
        rewind(output_unit)
        call execute_program(p,d)
        if(d%code/=2) then
            write(error_unit,*) 'Unexpected runtime acceptance: mutation',which
            error stop 'rank-three forged IR admitted'
        end if
        rewind(output_unit)
        read(output_unit,'(a)',iostat=ios) record
        if(ios==0) error stop 'failed rank-three execution leaked stdout'
    end do
    call parse_subset('integer :: aa(2,2)'//nl//'aa=7'//nl//'print *,123,aa(1,1)'//nl//'end',p,d)
    call require_parse()
    do e=1,p%ne
        if(p%expressions(e)%kind/=ex_element) cycle
        p%expressions(e)%third=p%expressions(e)%left
        exit
    end do
    rewind(output_unit)
    call execute_program(p,d)
    if(d%code/=2) error stop 'rank-two element admitted hidden third subscript'
    rewind(output_unit)
    read(output_unit,'(a)',iostat=ios) record
    if(ios==0) error stop 'hidden third metadata leaked stdout'
    ! Two fresh executions with equal explicit seeds must produce identical
    ! values and consume exactly eight draws, independently of GNU's RNG.
    call parse_subset(random_source,p,d)
    call require_parse()
    wanted=104729_int64
    do j=1,8
        wanted=modulo(wanted*16807_int64,2147483647_int64)
    end do
    do which=1,2
        state=104729_int64;d=diagnostic_t()
        rewind(output_unit)
        call execute_program(p,d,random_state=state)
        if(d%code/=0.or.state/=wanted) error stop 'rank-three RNG draw count/range failure'
        rewind(output_unit)
        read(output_unit,'(a)',iostat=ios) record
        if(ios/=0) error stop 'missing rank-three RNG values'
        if(which==1) first_record=record
        if(which==2.and.record/=first_record) error stop 'rank-three RNG reset is not deterministic'
    end do
    close(output_unit)
    write(error_unit,'(a)') 'PASS: 12 rank-three runtime mutations, atomic errors, seeded RNG range/count/determinism'
contains
    subroutine require_parse()
        if(d%code==0) return
        if(allocated(d%message)) write(error_unit,*) d%message
        error stop 'rank-three runtime baseline parse failed'
    end subroutine
end program test_rank_three_runtime
