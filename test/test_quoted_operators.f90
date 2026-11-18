! SPDX-License-Identifier: MIT
program test_quoted_operators
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    character(8),parameter::spellings(5)=[character(8)::'+','-','.not.','.flip.','//']
    integer::i,j,n,checks
    checks=0
    do i=1,size(spellings)
        source='program p'//nl//'character(8)::s'//nl// &
            "s='"//trim(spellings(i))//"'"//nl// &
            "if(s/='"//trim(spellings(i))//"') error stop 1"//nl//'end program'
        call parse_subset(source,p,d)
        call okay('quoted parse')
        n=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_unary.or.p%expressions(j)%kind==ex_user_call) &
                error stop 'quoted token changed into an operator'
            if(p%expressions(j)%kind==ex_literal.and.p%expressions(j)%typ==ty_character) n=n+1
        end do
        if(n/=2) error stop 'quoted literal count changed'
        call verify_frontend(source,p,d)
        call okay('quoted verify')
        call execute_program(p,d)
        call okay('quoted execute')
        checks=checks+1
    end do
    source='program p'//nl//"print *, 'a' '//' 'b'"//nl//'end program'
    call parse_subset(source,p,d)
    if(d%code/=1) error stop 'quoted concatenation token accepted as syntax'
    source='program p'//nl//"print *, '['"//nl//'end program'
    call parse_subset(source,p,d)
    call okay('promoted bracket literal parse')
    call verify_frontend(source,p,d)
    call okay('promoted bracket literal verify')
    print '(a,i0,a)','PASS: ',checks,' quoted literal IRs, one rejection and promoted bracket literal'
contains
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'quoted operator check failed'
        end if
    end subroutine
end program
