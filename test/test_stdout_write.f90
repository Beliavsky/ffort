! SPDX-License-Identifier: MIT
program test_stdout_write
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'write(*,"(i0)")42'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::which,pc,j,checks
    checks=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'parse baseline')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'adapter baseline')
    pc=0
    do j=1,p%nc
        if(p%code(j)%op==op_print)pc=j
    end do
    call expect(pc>0,'shared PRINT opcode')
    call execute_program(p,d)
    call expect(d%code==0,'runtime baseline')
    do which=1,16
        q=p;d=diagnostic_t()
        select case(which)
        case(1);q%code(pc)%symbol=1
        case(2);q%code(pc)%a=1
        case(3);q%code(pc)%b=1
        case(4);q%code(pc)%c=1
        case(5);q%code(pc)%d=1
        case(6);q%code(pc)%target=1
        case(7);q%code(pc)%component=1
        case(8);q%code(pc)%generic_id=1
        case(9);q%code(pc)%third=1
        case(10);q%code(pc)%bound_type=1
        case(11);q%code(pc)%bound_binding=1
        case(12);q%code(pc)%construct_name='forged'
        case(13);deallocate(q%code(pc)%items)
        case(14);q%code(pc)%items=[q%ne+1]
        case(15);q%code(pc)%format='(a)'
        case(16);q%expressions(q%code(pc)%items(1))%scope=999
        end select
        call verify_frontend(source,q,d)
        call expect(d%code/=0,'adapter corrupt output')
        d=diagnostic_t()
        call execute_program(q,d)
        call expect(d%code==2,'runtime corrupt output')
        checks=checks+2
    end do
    print *, 'PASS: stdout WRITE independent IR checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
