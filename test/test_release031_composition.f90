! SPDX-License-Identifier: MIT
! Synthetic TARGET/descriptor/CHARACTER/FINDLOC composition, not original utility code.
program test_release031_composition
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'integer,parameter::k=2'//nl//'character(3),target::words(2,1,1)'//nl// &
        'logical,allocatable,target::selected(:,:,:)'//nl// &
        'allocate(selected(2,1,1))'//nl//'selected=.true.'//nl//'words="ab"'//nl// &
        'call relay(words,selected)'//nl//'contains'//nl//'subroutine relay(x,m)'//nl// &
        'character(*),target,intent(in)::x(:,:,:)'//nl// &
        'logical,allocatable,target,optional,intent(in)::m(:,:,:)'//nl// &
        'call work(x,m)'//nl//'end subroutine'//nl//'subroutine work(x,m)'//nl// &
        'character(*),target,intent(in)::x(:,:,:)'//nl// &
        'logical,allocatable,optional,target,intent(in)::m(:,:,:)'//nl// &
        'character(len=len(x(1,1,1))),target::y(2,1)'//nl//'integer(8)::positions(2)'//nl// &
        'if(.not.present(m)) error stop 1'//nl//'y=x(:,:,1)'//nl// &
        'positions=findloc(y,"ab",mask=m(:,:,1),kind=8,back=.true.)'//nl// &
        'if(any(positions/=[2_8,1_8])) error stop 2'//nl// &
        'if(len(y)/=3) error stop 3'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::mutation,j,alloc_op,len_element,location,value_arg,mask_arg,checks,n,parameter_symbol
    checks=0
    do mutation=0,12
        call fresh()
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
    call fresh()
    n=p%ns
    call expect(count(p%symbols(:n)%is_target)==7,'seven TARGET descriptors and arrays preserved')
    do mutation=1,n
        call fresh()
        p%symbols(mutation)%is_target=.not.p%symbols(mutation)%is_target
        call verify_frontend(source,p,d)
        call expect(d%code==1,'forged TARGET source metadata rejected')
        checks=checks+1
    end do
    call fresh()
    parameter_symbol=0
    do j=1,p%ns
        if(p%symbols(j)%name=='k') parameter_symbol=j
    end do
    call expect(parameter_symbol>0,'parameter metadata present')
    p%symbols(parameter_symbol)%is_target=.true.
    call execute_program(p,d)
    call expect(d%code==2,'PARAMETER TARGET runtime metadata rejected')
    checks=checks+1
    call fresh()
    do j=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==0,'repeat execution restores descriptor state')
    end do
    print '(a,i0,a)','PASS: release 0.31 composition and ',checks,' adapter/runtime metadata rejections'
contains
    subroutine fresh()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        call expect(d%code==0,'composition parse')
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok) return
        print *,label,' mutation=',mutation,' code=',d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
