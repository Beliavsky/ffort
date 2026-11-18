! SPDX-License-Identifier: MIT
program test_optional_operator_rejection
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    integer::arity,slot,used,s,checks
    character(:),allocatable::valid,invalid
    checks=0
    do arity=1,2
        do slot=1,arity
            do used=0,1
                valid=fixture(arity,0,used)
                invalid=fixture(arity,slot,used)
                call parse_subset(valid,p,d)
                if(d%code/=0) error stop 'valid operator fixture parse failed'
                call verify_frontend(valid,p,d)
                if(d%code/=0) error stop 'valid operator fixture adapter failed'
                checks=checks+1
                ! Coherently mutate IR and source, so matching declaration
                ! OPTIONAL flags cannot hide an invalid operator interface.
                s=p%procedures(p%operators(1)%procedures(1))%args(slot)
                p%symbols(s)%is_optional=.true.
                call verify_frontend(invalid,p,d)
                if(d%code==0) error stop 'adapter admitted OPTIONAL operator operand'
                if(index(d%message,'defined operator arguments cannot be OPTIONAL')==0) then
                    print *,d%message
                    error stop 'adapter did not independently validate the operator signature'
                end if
                checks=checks+1
                call parse_subset(invalid,p,d)
                if(d%code==0) error stop 'recognizer admitted OPTIONAL operator operand'
                if(index(d%message,'Defined operator arguments cannot be OPTIONAL')==0) &
                    error stop 'recognizer missed OPTIONAL operator signature'
                checks=checks+1
            end do
        end do
    end do
    print '(a,i0,a)','PASS: ',checks,' required operator operand baseline/recognizer/adapter checks'
contains
    function fixture(arity,slot,used) result(source)
        integer,intent(in)::arity,slot,used
        character(:),allocatable::source,args,expression,decl
        character(*),parameter::nl=new_line('a')
        integer::j
        args='x';expression='.test. 2'
        if(arity==2) then
            args='x,z';expression='2 .test. 3'
        end if
        if(used==0) expression='42'
        source='module ops'//nl//'implicit none'//nl// &
            'interface operator(.test.)'//nl//'module procedure f'//nl//'end interface'//nl// &
            'contains'//nl//'pure integer function f('//args//') result(y)'//nl
        do j=1,arity
            decl='integer,intent(in)'
            if(slot==j) then
                decl=decl//',optional '
            else
                decl=decl//'          '
            end if
            if(j==1) then
                decl=decl//'::x'
            else
                decl=decl//'::z'
            end if
            source=source//decl//nl
        end do
        source=source//'y=x'//nl//'end function'//nl//'end module'//nl// &
            'program main'//nl//'use ops'//nl//'implicit none'//nl// &
            'print *, '//expression//nl//'end program'//nl
    end function
end program
