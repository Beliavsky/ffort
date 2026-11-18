! SPDX-License-Identifier: MIT
program test_repl_growth_source
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_repl_growth_source,only:plain_scalar_declaration,stage_scalar_declaration
    implicit none
    character(*),parameter::nl=new_line('a'),header='program repl_session'//nl//'implicit none'//nl
    character(*),parameter::footer='end program repl_session'//nl
    character(60),parameter::bad_lines(18)=[character(60):: &
        'integer x','integer :: x,y','integer(4) :: x','integer, save :: x', &
        'real :: x=1','logical :: x(2)','character :: x','integer :: x; print *,1', &
        'integer :: x &','integer :: 1x','integer :: _x','integer ::','real :: x%y', &
        'integer :: if','integer :: program','integer :: x y','integer :: x()','logical :: x=>y']
    type(program_t)::p
    type(diagnostic_t)::d
    character(:),allocatable::body,staged,expected,original
    integer::checks=0,k,line
    call check(plain_scalar_declaration('integer :: fresh'),'integer grammar')
    call check(plain_scalar_declaration('  ReAl :: Fresh ! Keep CASE & ;'),'case and comment')
    call check(plain_scalar_declaration(achar(9)//'logical'//achar(9)//':: okay'),'tab grammar')
    do k=1,size(bad_lines)
        call check(.not.plain_scalar_declaration(trim(bad_lines(k))),'strict excluded grammar')
    end do
    body='integer :: i'//nl//'! Before executable'//nl//'i=1'//nl
    call fixture()
    call stage('  REAL :: fresh ! Case',5,.true.)
    expected='integer :: i'//nl//'! Before executable'//nl//'  REAL :: fresh ! Case'//nl//'i=1'//nl
    call check(staged==expected,'preserve spelling and exact insertion')
    body='integer :: i'//nl//'i = &'//nl//' & 1'//nl
    call fixture();call stage('logical :: flag',4,.true.)
    body='integer :: i'//nl//'do i=1,2'//nl//'if (i==1) then'//nl// &
        'print *, i'//nl//'endif'//nl//'enddo'//nl
    call fixture();call stage('integer :: fresh',4,.true.)
    body='integer :: i'//nl//'! no executable'//nl//nl
    call fixture();call stage('real :: fresh',6,.true.)
    body=''
    call fixture();call stage('integer :: fresh',3,.true.)
    body='! only a comment'//nl
    call fixture();call stage('integer :: fresh',4,.true.)
    body='integer :: &'//nl//'i'//nl//'i=1'//nl
    call fixture();call stage('integer :: fresh',0,.false.)
    body='integer :: i; real :: r'//nl//'i=1'//nl
    call fixture();call stage('integer :: fresh',0,.false.)
    body='integer :: i'//nl//'i=1'//nl
    call fixture()
    d=diagnostic_t();call stage_scalar_declaration(body,'real :: fresh',p,2,len(body),100,staged,line,d)
    call check(d%code/=0.and..not.allocated(staged),'byte cap rollback')
    d=diagnostic_t();call stage_scalar_declaration(body,'real :: fresh',p,2,10000,2,staged,line,d)
    call check(d%code/=0.and..not.allocated(staged),'line cap rollback')
    d=diagnostic_t();call stage_scalar_declaration(body,'real :: fresh'//nl,p,2,10000,100,staged,line,d)
    call check(d%code/=0.and..not.allocated(staged),'physical line only')
    print *, 'growth source checks: ',checks
contains
    subroutine fixture()
        d=diagnostic_t();call parse_subset(header//body//footer,p,d)
        call check(d%code==0,'fixture parses')
        call verify_frontend(header//body//footer,p,d)
        call check(d%code==0,'fixture frontend')
    end subroutine
    subroutine stage(text,want_line,success)
        character(*),intent(in)::text
        integer,intent(in)::want_line
        logical,intent(in)::success
        original=body;d=diagnostic_t()
        call stage_scalar_declaration(body,text,p,2,10000,100,staged,line,d)
        call check((d%code==0).eqv.success,'staging outcome')
        call check(body==original,'original untouched')
        if(success)then
            call check(allocated(staged).and.line==want_line,'insertion boundary')
            call check(len(staged)==len(body)+len(text)+1,'exact one-line growth')
        else
            call check(.not.allocated(staged),'failure has no staged source')
        end if
    end subroutine
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *, 'FAIL ',label
            if(allocated(d%message))print *,d%message
            stop 1
        end if
        checks=checks+1
    end subroutine
end program
