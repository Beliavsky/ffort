! SPDX-License-Identifier: MIT
program test_optional_character_forwarding
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    type(program_t)::p
    type(diagnostic_t)::d
    character(:),allocatable::source
    integer::form,which,j,actual,checks
    checks=0
    do form=1,2
        if(form==1)then
            source='program main'//nl//'call outer()'//nl//'contains'//nl// &
                'subroutine outer(x)'//nl//'character(*),optional,intent(in)::x(:)'//nl// &
                'call inner(x)'//nl//'end subroutine'//nl
        else
            source='program main'//nl//'character(4),allocatable::a(:)'//nl// &
                'call inner(a)'//nl//'contains'//nl
        end if
        source=source//'subroutine inner(x)'//nl//'character(*),optional,intent(in)::x(:)'//nl// &
            'if(present(x)) error stop 1'//nl//'end subroutine'//nl//'end program'
        do which=1,7
            call parse_subset(source,p,d)
            call require(d%code==0,'fixture parse')
            actual=0
            do j=1,p%nc
                if(p%code(j)%op/=op_call)cycle
                if(.not.allocated(p%code(j)%items))cycle
                if(size(p%code(j)%items)/=1)cycle
                if(p%code(j)%items(1)>0)actual=p%code(j)%items(1)
            end do
            call require(actual>0,'fixture actual')
            select case(which)
            case(2);p%expressions(actual)%scope=42
            case(3);p%expressions(actual)%extent=-2_int64
            case(4);p%expressions(actual)%extent=int(max_array_elements,int64)+1_int64
            case(5);p%expressions(actual)%rank=3
            case(6);p%expressions(actual)%character_len=37
            case(7);p%expressions(actual)%rank=2;p%expressions(actual)%dims=[-2_int64,-1_int64,1_int64]
            end select
            call execute_program(p,d)
            call require((d%code==0).eqv.(which==1),'runtime missing-actual descriptor')
            if(which/=1)checks=checks+1
        end do
    end do
    print *, 'PASS: absent/unallocated forwarding descriptor mutations:',checks
contains
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' form=',form,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
