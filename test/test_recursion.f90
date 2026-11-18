! SPDX-License-Identifier: MIT
program test_recursion
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser, only:parse_subset
    use fi_frontend, only:verify_frontend
    use fi_runtime, only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'if(f(6)/=720) error stop 1'//nl// &
        'contains'//nl//'pure recursive integer function f(n) result(v)'//nl// &
        'integer,intent(in)::n'//nl//'integer::saved'//nl//'saved=n'//nl// &
        'if(n==0) then'//nl//'v=1'//nl//'else'//nl//'v=f(n-1)*saved'//nl// &
        'end if'//nl//'end function'//nl//'end program'
    character(*),parameter::acyclic='program p'//nl//'if(f(2)/=2) error stop 1'//nl// &
        'contains'//nl//'recursive integer function f(n) result(v)'//nl// &
        'integer,intent(in)::n'//nl//'v=n'//nl//'end function'//nl//'end program'
    character(*),parameter::effects='program p'//nl//'if(f(3)/=3) error stop 1'//nl// &
        'contains'//nl//'integer function f(n) result(v)'//nl//'integer,intent(in)::n'//nl// &
        'call a(n)'//nl//'v=n'//nl//'end function'//nl// &
        'recursive subroutine a(n)'//nl//'integer,intent(in)::n'//nl// &
        'if(n>0) call b(n-1)'//nl//'return'//nl//'end subroutine'//nl// &
        'recursive subroutine b(n)'//nl//'integer,intent(in)::n'//nl// &
        'if(n>0) call a(n-1)'//nl//'return'//nl//'end subroutine'//nl//'end program'
    integer::checks=0,i,target
    call parse_subset(source,p,d)
    call expect(d%code==0,'recursive source parses')
    call expect(p%procedures(1)%is_recursive,'IR recursion metadata')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'recursive source independently verified')
    call execute_program(p,d)
    call expect(d%code==0,'recursive local values survive descent')
    call parse_subset(source,p,d)
    p%procedures(1)%is_recursive=.false.
    call verify_frontend(source,p,d)
    call expect(d%code==1,'adapter rejects unmarked cycle')
    call parse_subset(source,p,d)
    p%procedures(1)%is_recursive=.false.
    call execute_program(p,d)
    call expect(d%code==2,'runtime rejects unmarked recursion')
    call expect(index(d%message,'requires RECURSIVE')>0,'runtime recursion diagnostic')
    call parse_subset(source,p,d)
    p%procedures(1)%is_elemental=.true.
    call execute_program(p,d)
    call expect(d%code==2,'runtime rejects recursive ELEMENTAL metadata')
    call parse_subset(source,p,d)
    call execute_program(p,d,max_steps=10_int64)
    call expect(d%code==2,'recursive calls share the work budget')
    call parse_subset(acyclic,p,d)
    p%procedures(1)%is_recursive=.false.
    call verify_frontend(acyclic,p,d)
    call expect(d%code==1,'adapter detects lost RECURSIVE prefix without a cycle')
    call expect(index(d%message,'RECURSIVE attribute differs')>0,'prefix mismatch diagnostic')
    call parse_subset(effects,p,d)
    call expect(d%code==0,'effect-free mutual recursion parses')
    call verify_frontend(effects,p,d)
    call expect(d%code==0,'effect-free mutual recursion verified')
    call execute_program(p,d)
    call expect(d%code==0,'effect-free mutual recursion executes')
    do target=2,3
        call parse_subset(effects,p,d)
        do i=1,p%nc
            if(p%code(i)%scope/=target.or.p%code(i)%op/=op_return) cycle
            p%code(i)%op=op_print
            if(allocated(p%code(i)%items)) deallocate(p%code(i)%items)
            allocate(p%code(i)%items(0))
            exit
        end do
        call verify_frontend(effects,p,d)
        call expect(d%code==1,'cycle member cannot hide a transitive external effect')
        call expect(index(d%message,'transitively performs external effects')>0,'effect analysis diagnostic')
    end do
    print '(a,i0,a)','PASS: ',checks,' recursion metadata, frame and safety checks'
contains
    subroutine expect(ok,what)
        logical,intent(in)::ok
        character(*),intent(in)::what
        checks=checks+1
        if(ok) return
        print *,what,d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
