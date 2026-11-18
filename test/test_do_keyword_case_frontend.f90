! SPDX-License-Identifier: MIT
program test_do_keyword_case_frontend
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:scalar_session_t,reset_scalar_session,execute_scalar_session,inspect_scalar_session
    implicit none
    character(*),parameter::nl=new_line('a')
    character(2),parameter::openers(3)=[character(2)::'do','DO','dO']
    character(6),parameter::closers(6)=[character(6)::'end do','END DO','EnD dO','enddo','ENDDO','eNdDo']
    character(*),parameter::literal='MiXeD END DO enddo Do'
    character(:),allocatable::source
    type(program_t)::p
    type(diagnostic_t)::d
    type(scalar_session_t)::session
    type(value_t)::v
    logical::defined
    integer::i,j,k,checks
    checks=0
    do i=1,size(openers)
        do j=1,size(closers)
            do k=1,size(closers)
                source='program p'//nl//'implicit none'//nl// &
                    'integer :: i,j,n'//nl//'character(32) :: text'//nl//'n=0'//nl// &
                    trim(openers(i))//' i=1,2'//nl//trim(openers(4-i))//' j=1,3'//nl// &
                    'n=n+1'//nl//"text='"//literal//"'"//nl// &
                    trim(closers(j))//nl//trim(closers(k))//nl//'end program p'//nl
                d=diagnostic_t();call parse_subset(source,p,d);call check(d%code==0,'subset parse')
                call verify_frontend(source,p,d);call check(d%code==0,'producer binding')
                call reset_scalar_session(session)
                call execute_scalar_session(session,p,d);call check(d%code==0,'retained execution')
                call inspect_scalar_session(session,3,v,defined,d)
                call check(d%code==0.and.defined.and.v%i==6,'nested count')
                call inspect_scalar_session(session,4,v,defined,d)
                call check(d%code==0.and.defined,'literal defined')
                call check(v%s==literal,'literal case preserved')
            end do
        end do
    end do
    print *, 'DO keyword case checks: ',checks
contains
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *,i,j,k,' FAIL ',label
            if(allocated(d%message))print *,d%message
            stop 1
        end if
        checks=checks+1
    end subroutine
end program
