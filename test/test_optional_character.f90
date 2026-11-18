! SPDX-License-Identifier: MIT
program test_optional_character
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,decl
    integer::form,i,s,checks
    checks=0
    do form=1,6
        select case(form)
        case(1);decl='character(4),optional,intent(in)::x'
        case(2);decl='character(*),optional,intent(in)::x'
        case(3);decl='character(4),optional,intent(in)::x(:)'
        case(4);decl='character(*),optional,intent(in)::x(:,:)'
        case(5);decl='character(4),allocatable,optional,intent(in)::x(:)'
        case(6);decl='character(:),allocatable,optional,intent(in)::x(:,:)'
        end select
        source='program main'//nl//'call work()'//nl//'contains'//nl// &
            'subroutine work(x)'//nl//decl//nl// &
            'if(present(x)) error stop 1'//nl//'end subroutine'//nl//'end program'
        do i=1,6
            call parse_subset(source,p,d)
            call require(d%code==0,'parse')
            s=p%procedures(1)%args(1)
            select case(i)
            case(2);p%symbols(s)%is_optional=.false.
            case(3);p%symbols(s)%is_dummy=.false.
            case(4);p%symbols(s)%rank=4
            case(5);p%symbols(s)%typ=ty_derived_base
            case(6);p%symbols(s)%character_len=65537
            end select
            call verify_frontend(source,p,d)
            call require((d%code==0).eqv.(i==1),'adapter')
            d=diagnostic_t()
            call execute_program(p,d)
            call require((d%code==0).eqv.(i==1),'runtime')
            if(i/=1)checks=checks+2
        end do
    end do
    print *, 'PASS: OPTIONAL CHARACTER descriptor mutations:', checks
contains
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' form=',form,' mutation=',i
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
