! SPDX-License-Identifier: MIT
! Runtime-only proof using independently constructed pointer IR. The recognizer
! initially parses equivalent allocatable descriptors; only the tested descriptor
! flags and association opcode are changed below, without frontend approval.
program test_pointer_runtime_views
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,n
    character(:),allocatable::source
    source='program main'//nl//'integer,target::a(-1:1)'//nl// &
      'integer,allocatable::p(:)'//nl//'a=[1,2,3]'//nl//'p=a'//nl// &
      'p(0)=9'//nl//'if(a(0)/=9) error stop 1'//nl//'a(1)=8'//nl// &
      'if(p(1)/=8.or.lbound(p,1)/=-1) error stop 2'//nl//'end'
    call run(source,0,'main whole target alias')
    source='module m'//nl//'contains'//nl//'subroutine getcol(x,p)'//nl// &
      'integer,target,intent(inout)::x(:,:)'//nl//'integer,allocatable,intent(out)::p(:)'//nl// &
      'p=x(:,2)'//nl//'x(2,2)=7'//nl//'end subroutine'//nl//'end module'//nl// &
      'program main'//nl//'use m'//nl//'integer,target::a(2,2)'//nl// &
      'integer,allocatable::p(:)'//nl//'a=0'//nl//'a(:,2)=[3,4]'//nl// &
      'call getcol(a,p)'//nl//'if(p(2)/=7) error stop 1'//nl//'p(1)=9'//nl// &
      'if(a(1,2)/=9) error stop 2'//nl//'a(2,2)=8'//nl//'if(p(2)/=8) error stop 3'//nl//'end'
    call run(source,0,'caller-backed TARGET dummy escape')
    source='module m'//nl//'contains'//nl//'subroutine bad(p)'//nl// &
      'integer,target::a(2)'//nl//'integer,allocatable,intent(out)::p(:)'//nl// &
      'a=3'//nl//'p=a'//nl//'end subroutine'//nl//'end module'//nl// &
      'program main'//nl//'use m'//nl//'integer,allocatable::p(:)'//nl//'call bad(p)'//nl//'end'
    call run(source,2,'expired local TARGET escape')
    if(index(d%message,'lifetime has expired')==0) error stop 'wrong stale-lifetime diagnostic'
    source='program main'//nl//'integer,target::a(2,3)'//nl//'integer,allocatable::p(:)'//nl// &
      'a=0'//nl//'a(2,:)=[3,4,5]'//nl//'p=a(2,3:1:-1)'//nl// &
      'if(p(1)/=5.or.p(3)/=3) error stop 1'//nl//'p(2)=9'//nl// &
      'if(a(2,2)/=9) error stop 2'//nl//'end'
    call run(source,0,'negative-stride row view')
    source='program main'//nl//'integer,target::a(0,2)'//nl//'integer,allocatable::p(:)'//nl// &
      'p=a(:,2)'//nl//'if(size(p)/=0) error stop 1'//nl//'end'
    call run(source,0,'empty caller-backed section')
    print '(a)','PASS: five backed-view runtime scenarios including escaped caller view and expired local rejection'
contains
    subroutine run(text,expected,label)
        character(*),intent(in)::text,label
        integer,intent(in)::expected
        d=diagnostic_t()
        call parse_subset(text,p,d)
        if(d%code/=0) then
            print *,label,d%line,d%column,d%message
            error stop 'runtime-view source parse failed'
        end if
        do i=1,p%ns
            if(p%symbols(i)%name/='p') cycle
            p%symbols(i)%is_allocatable=.false.;p%symbols(i)%is_pointer=.true.
        end do
        n=0
        do i=1,p%nc
            j=p%code(i)%symbol
            if(j<1.or.j>p%ns) cycle
            if(p%code(i)%op/=op_assign.or.p%symbols(j)%name/='p') cycle
            if(p%code(i)%b/=0.or.p%code(i)%c/=0) cycle
            p%code(i)%op=op_pointer_assign;n=n+1
        end do
        if(n==0) error stop 'runtime test missing association'
        call execute_program(p,d)
        if(d%code/=expected) then
            print *,label,d%code
            if(allocated(d%message)) print *,d%message
            error stop 'backed pointer runtime scenario failed'
        end if
    end subroutine
end program
