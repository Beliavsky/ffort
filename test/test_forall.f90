! SPDX-License-Identifier: MIT
program test_forall
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::i,j,a(3,3)'//nl//'i=7'//nl//'j=8'//nl// &
        'a=reshape([1,2,3,4,5,6,7,8,9],[3,3])'//nl// &
        'forall(i=1:3,j=1:3,i/=j)'//nl//'a(i,j)=a(j,i)'//nl//'end forall'//nl// &
        'if(i/=7.or.j/=8) error stop 1'//nl//'if(any(a(:,1)/=[1,4,7])) error stop 2'//nl// &
        'if(any(a(:,2)/=[2,5,8])) error stop 3'//nl//'end program'
    character(*),parameter::pure_source='program p'//nl//'integer::i,a(2)'//nl// &
        'forall(i=1:2) a(i)=f(i)'//nl//'contains'//nl//'pure integer function f(x)'//nl// &
        'integer,intent(in)::x'//nl//'f=x'//nl//'end function'//nl//'end program'
    integer::which,entry,j,body,iv,mask,checks
    checks=0
    do which=0,18
        call baseline()
        select case(which)
        case(1);p%code(entry)%items=[1,2,3]
        case(2);deallocate(p%code(entry)%items)
        case(3);p%code(entry)%items(1)=0
        case(4);p%code(entry)%items(5)=p%code(entry)%items(1)
        case(5);p%code(entry)%items(2)=0
        case(6);p%code(entry)%items(3)=p%ne+1
        case(7);p%code(entry)%items(4)=p%ne+1
        case(8);p%code(entry)%a=0
        case(9);p%code(entry)%target=entry
        case(10);p%code(entry)%target=p%nc+2
        case(11);p%code(body)%op=op_return
        case(12);p%code(body)%symbol=0
        case(13);p%code(body)%b=0;p%code(body)%d=0
        case(14);p%symbols(iv)%real_kind=16
        case(15);p%code(entry)%a=p%code(entry)%items(2)
        case(16);p%code(entry)%scope=1
        case(17);p%code(body)%scope=1
        case(18);p%code(entry)%items(2)=p%expressions(mask)%left
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==0),'adapter mutation',which)
    end do
    do which=0,18
        call baseline()
        select case(which)
        case(1);p%code(entry)%items=[1,2,3]
        case(2);deallocate(p%code(entry)%items)
        case(3);p%code(entry)%items(1)=0
        case(4);p%code(entry)%items(5)=p%code(entry)%items(1)
        case(5);p%code(entry)%items(2)=0
        case(6);p%code(entry)%items(3)=p%ne+1
        case(7);p%code(entry)%items(4)=p%ne+1
        case(8);p%code(entry)%a=p%ne+1
        case(9);p%code(entry)%target=entry
        case(10);p%code(entry)%target=p%nc+2
        case(11);p%code(body)%op=op_return
        case(12);p%code(body)%symbol=0
        case(13);p%code(body)%b=0;p%code(body)%d=0
        case(14);p%symbols(iv)%real_kind=16
        case(15);p%code(entry)%a=p%code(entry)%items(2)
        case(16);p%code(entry)%scope=1
        case(17);p%code(body)%scope=1
        case(18);p%code(entry)%items(2)=p%expressions(mask)%left
        end select
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==0),'runtime mutation',which)
        if(which/=0) call expect(d%code==2,'checked runtime status',which)
    end do
    call parse_subset(pure_source,p,d)
    call expect(d%code==0,'pure source parses',0)
    p%procedures(1)%is_pure=.false.
    call execute_program(p,d)
    call expect(d%code==2,'runtime purity guard',0)
    call baseline()
    call execute_program(p,d,max_steps=10_int64)
    call expect(d%code==2,'execution budget',0)
    print '(a,i0,a)','PASS: FORALL semantic baselines and ',checks,' adapter/runtime checks'
contains
    subroutine expect(ok,what,which)
        logical,intent(in)::ok
        character(*),intent(in)::what
        integer,intent(in)::which
        checks=checks+1
        if(ok) return
        print *,trim(what),which,d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
    subroutine baseline()
        call parse_subset(source,p,d)
        call expect(d%code==0,'baseline parses',0)
        entry=0
        do j=1,p%nc
            if(p%code(j)%op==op_forall) entry=j
        end do
        call expect(entry>0,'FORALL emitted',0)
        body=entry+1;iv=p%code(entry)%items(1);mask=p%code(entry)%a
    end subroutine
end program
