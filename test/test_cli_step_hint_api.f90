! SPDX-License-Identifier: MIT
program test_cli_step_hint_api
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir,only:program_t,diagnostic_t
    use fi_parser,only:parse_subset
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    type(program_t)::p
    type(diagnostic_t)::d
    call parse_subset('program p'//nl//'implicit none'//nl//'integer::x'//nl//'x=1'//nl//'end program',p,d)
    if(d%code/=0)error stop 'step-budget API baseline parse failed'
    call execute_program(p,d,max_steps=1_int64)
    if(d%code/=2.or.d%line/=4.or.d%column/=3)error stop 'step-budget API status/location changed'
    if(d%message/='execution step limit exceeded')error stop 'CLI advice leaked into reusable API'
    print '(a)','PASS: reusable step-budget API diagnostic unchanged'
end program
