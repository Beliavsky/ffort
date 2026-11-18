! SPDX-License-Identifier: MIT
program test_internal_write_element
    use,intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'character(4)::a(2)'//nl//"write(a(2),'(i2.2)')7"//nl//'end program'//nl
    integer::which,i,pc,e,s,checks
    checks=0
    do which=1,20
        call parse_subset(source,p,d)
        call expect(d%code==0,'parse original array-element WRITE')
        pc=0
        do i=1,p%nc
            if(p%code(i)%op==op_write_internal)pc=i
        end do
        call expect(pc>0,'internal WRITE located')
        e=p%code(pc)%a;s=p%code(pc)%symbol
        call expect(e>0,'element designator retained')
        select case(which)
        case(2);p%code(pc)%a=0
        case(3);p%code(pc)%a=p%ne+1
        case(4);p%code(pc)%b=1
        case(5);p%code(pc)%third=1
        case(6);p%code(pc)%component=1
        case(7);p%expressions(e)%kind=ex_variable
        case(8);p%expressions(e)%symbol=0
        case(9);p%expressions(e)%rank=1
        case(10);p%expressions(e)%character_len=3
        case(11);p%expressions(e)%left=p%ne+1
        case(12);p%expressions(e)%right=p%expressions(e)%left
        case(13);p%expressions(e)%parenthesized=.true.
        case(14);p%expressions(e)%real_kind=8
        case(15);p%expressions(e)%scope=1
        case(16);p%expressions(e)%generic_id=1
        case(17);p%expressions(e)%value%tag=ty_character
        case(18);p%symbols(s)%is_parameter=.true.
        case(19);p%expressions(p%code(pc)%items(1))%left=p%code(pc)%items(1)
        case(20);p%expressions(p%code(pc)%items(1))%left=p%ne+1
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'adapter rejects malformed target metadata')
        d=diagnostic_t()
        call execute_program(p,d,max_steps=10000_int64)
        call expect((d%code==0).eqv.(which==1),'runtime independently rejects malformed target metadata')
        if(which/=1)call expect(d%code==2,'runtime rejection phase')
    end do
    print *,'PASS: internal WRITE element draft native assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,'FAIL:',label,which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
