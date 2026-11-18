! SPDX-License-Identifier: MIT
program test_optional_dim
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(7),parameter::names(10)=[character(7):: &
        'all','any','count','sum','product','minval','maxval','lbound','ubound','size']
    character(:),allocatable::source,arg,array
    integer::i,j,form,e,child,checks
    checks=0
    do i=1,size(names)
        array='[1,2]'
        if(i<=3) array='[.true.,.false.]'
        do form=1,3
            select case(form)
            case(1);arg='d'
            case(2);arg='(d)'
            case(3);arg='d+0'
            end select
            source='program p'//nl//'implicit none'//nl//'call f(1)'//nl//'contains'//nl// &
                'subroutine f(d)'//nl//'integer,optional,intent(in)::d'//nl// &
                'print *,'//trim(names(i))//'('//array//',dim='//arg//')'//nl// &
                'end subroutine'//nl//'end program'
            call parse_subset(source,p,d)
            if(form==1.and.i<10) then
                call expect(d%code/=0,'direct OPTIONAL DIM rejected')
                call expect(index(d%message,'DIM must not be a direct OPTIONAL dummy')>0,'parser diagnostic')
                cycle
            end if
            call expect(d%code==0,'valid dimension expression parses')
            call verify_frontend(source,p,d)
            call expect(d%code==0,'valid dimension expression adapter')
            if(form/=2) cycle
            e=0
            do j=1,p%ne
                if(p%expressions(j)%op==names(i)) e=j
            end do
            call expect(e>0,'intrinsic call found')
            child=p%expressions(e)%args(2)
            p%expressions(child)%parenthesized=.false.
            d=diagnostic_t()
            call verify_frontend(source,p,d)
            if(i<10)then
                call expect(d%code/=0,'adapter independently rejects optional DIM')
                call expect(index(d%message,'DIM must not be a direct OPTIONAL dummy')>0,'adapter diagnostic')
            else
                call expect(d%code==0,'SIZE exception is preserved')
            end if
        end do
    end do
    print *, 'PASS: OPTIONAL DIM validation checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' ',names(i),' form ',form
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
