! SPDX-License-Identifier: MIT
program test_repeat_intrinsic
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant, execute_program
    implicit none
    type(program_t) :: p
    type(diagnostic_t) :: d
    type(value_t) :: v
    character(*), parameter :: nl=new_line('a')
    character(:), allocatable :: source, expression, call_text
    integer :: form, mutation, i, e, s, n, checks
    checks=0
    do form=1,6
        select case(form)
        case(1);call_text="repeat(ncopies=3_8,string='a ')";expression=call_text
        case(2);call_text="repeat('a ',3)";expression='kind('//call_text//')'
        case(3);call_text="repeat('a ',3)";expression='len('//call_text//')'
        case(4);call_text="repeat('',3)";expression='len('//call_text//')'
        case(5);call_text="repeat('a ',0)";expression="'<'//"//call_text//"//'>'"
        case(6);call_text="repeat('',0)";expression='kind('//call_text//')'
        end select
        source='program p'//nl//'implicit none'//nl//'print *,'//expression//nl//'end program'
        do mutation=0,23
            call parse_subset(source,p,d)
            call expect(d%code==0,'baseline parse')
            e=0
            do i=1,p%ne
                if(p%expressions(i)%op=='repeat') e=i
            end do
            call expect(e>0,'REPEAT node retained')
            call expect(size(p%expressions(e)%args)==2,'canonical arity')
            s=p%expressions(e)%args(1);n=p%expressions(e)%args(2)
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_integer
            case(2);p%expressions(e)%real_kind=8
            case(3);p%expressions(e)%rank=1
            case(4);p%expressions(e)%extent=1
            case(5);p%expressions(e)%dims=[1_int64,0_int64,0_int64]
            case(6);p%expressions(e)%intrinsic_mask=1
            case(7);p%expressions(e)%character_len=p%expressions(e)%character_len+1
            case(8);p%expressions(e)%character_len=-1
            case(9);p%expressions(e)%args=[s]
            case(10);p%expressions(e)%args=[s,n,n]
            case(11);deallocate(p%expressions(e)%args)
            case(12);p%expressions(e)%args(1)=0
            case(13);p%expressions(e)%args(2)=p%ne+1
            case(14);p%expressions(e)%args(1)=e
            case(15);p%expressions(e)%args(2)=e
            case(16);p%expressions(s)%typ=ty_integer
            case(17);p%expressions(s)%real_kind=8
            case(18);p%expressions(s)%rank=1
            case(19);p%expressions(n)%typ=ty_real
            case(20);p%expressions(n)%real_kind=16
            case(21);p%expressions(n)%rank=1
            case(22);p%expressions(s)%character_len=p%expressions(s)%character_len+1
            case(23);p%expressions(e)%character_len=-2
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter mutation validation')
            d=diagnostic_t()
            call evaluate_constant(p,e,v,d)
            call expect((d%code==0).eqv.(mutation==0),'direct constant mutation validation')
            if(mutation==0) then
                call expect(v%tag==ty_character,'result character tag')
                call expect(allocated(v%s),'result character storage')
                if(form<=3) then
                    call expect(v%s=='a a a '.and.len(v%s)==6,'blanks and copies')
                else
                    call expect(len(v%s)==0,'empty result')
                end if
            end if
            d=diagnostic_t()
            call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime context mutation validation')
        end do
    end do
    print *, 'PASS: REPEAT independent mutation assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' form ',form,' mutation ',mutation
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
