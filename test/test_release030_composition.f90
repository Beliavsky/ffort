! SPDX-License-Identifier: MIT
! Synthetic 0.30 composition scaffold; no original utility source is rewritten.
program test_release030_composition
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'character(4) words(1,1,1)'//nl//'logical,allocatable :: selected(:,:,:)'//nl// &
        'allocate(selected(1,1,1))'//nl//'selected=.true.'//nl//'words="ab"'//nl// &
        'call work(words,selected)'//nl//'contains'//nl//'subroutine work(x,m)'//nl// &
        'character(*),intent(in) :: x(:,:,:)'//nl// &
        'logical,allocatable,intent(in) :: m(:,:,:)'//nl// &
        'character(len=len(x(1,1,1))) y(1,1)'//nl//'integer(8) positions(2)'//nl// &
        'y=x(:,:,1)'//nl//'positions=findloc(y,"ab",mask=m(:,:,1),kind=8)'//nl// &
        'if(any(positions/=[1_8,1_8])) error stop 1'//nl// &
        'if(len(y)/=4) error stop 2'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::mutation,j,alloc_op,len_element,location,value_arg,mask_arg,checks
    checks=0
    do mutation=0,12
        call parse_subset(source,p,d)
        call expect(d%code==0,'composition parse')
        alloc_op=0;len_element=0;location=0
        do j=1,p%nc
            if(p%code(j)%op==op_allocate) alloc_op=j
        end do
        do j=1,p%ne
            if(p%expressions(j)%op=='len') then
                if(allocated(p%expressions(j)%args)) then
                    if(size(p%expressions(j)%args)==1) then
                        if(p%expressions(p%expressions(j)%args(1))%kind==ex_element) &
                            len_element=p%expressions(j)%args(1)
                    end if
                end if
            end if
            if(p%expressions(j)%op=='findloc') location=j
        end do
        call expect(alloc_op>0.and.len_element>0.and.location>0,'composition metadata present')
        value_arg=p%expressions(location)%args(2)
        mask_arg=p%expressions(location)%args(3)
        select case(mutation)
        case(1);p%code(alloc_op)%items(6)=0
        case(2);p%symbols(p%code(alloc_op)%symbol)%real_kind=8
        case(3);p%expressions(len_element)%third=0
        case(4);p%expressions(len_element)%third=p%ne+1
        case(5);p%expressions(len_element)%character_len=2
        case(6);p%expressions(len_element)%scope=999
        case(7);p%expressions(mask_arg)%typ=ty_integer
        case(8);p%expressions(mask_arg)%rank=3
        case(9);p%expressions(value_arg)%rank=1
        case(10);p%expressions(location)%extent=99_int64
        case(11);p%expressions(location)%real_kind=16
        case(12);p%expressions(location)%args(2)=location
        end select
        call verify_frontend(source,p,d)
        call expect(d%code==merge(0,1,mutation==0),'independent adapter')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==merge(0,2,mutation==0),'direct runtime')
        if(mutation/=0) checks=checks+2
    end do
    print '(a,i0,a)','PASS: release 0.30 composition and ',checks,' adapter/runtime metadata rejections'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok) return
        print *,label,' mutation=',mutation,' code=',d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
