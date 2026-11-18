! SPDX-License-Identifier: MIT
program test_feature_integration
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    type(program_t) :: p
    type(diagnostic_t) :: d
    character(*),parameter :: nl=new_line('a')
    character(*),parameter :: source='program p'//nl// &
        'integer(kind=8),parameter :: aa(2)=[9007199254740993_8,9223372036854775807_8]'//nl// &
        'integer(kind=8),parameter :: bb=9007199254740993_8'//nl// &
        'select case(aa(1))'//nl// &
        'case(9007199254740993_8)'//nl// &
        'if (bb/=aa(1)) error stop "cache differs"'//nl// &
        'case default'//nl//'error stop "selector differs"'//nl// &
        'end select'//nl//'end program'
    integer :: which
    do which=1,5
        call parse_subset(source,p,d)
        call require_ok('parse')
        select case(which)
        case(2)
            p%symbols(1)%constant_values(1)%real_kind=4
        case(3)
            p%symbols(1)%constant_values(1)%tag=ty_real
        case(4)
            p%symbols(2)%constant_value%real_kind=4
        case(5)
            p%symbols(1)%constant_values(2)%real_kind=4
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('frontend baseline')
            call execute_program(p,d)
            call require_ok('runtime baseline')
        else
            if(d%code==0) error stop 'malformed INTEGER8 cache admitted by adapter'
            if(which==2.or.which==3) then
                d=diagnostic_t()
                call execute_program(p,d)
                if(d%code/=2) error stop 'malformed INTEGER8 array cache admitted at runtime'
            end if
        end if
    end do
    print '(a)', 'PASS: wide INTEGER SELECT/PARAMETER baseline and four adapter cache mutations'
contains
    subroutine require_ok(label)
        character(*),intent(in) :: label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected integration failure'
        end if
    end subroutine
end program
