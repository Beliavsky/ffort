! SPDX-License-Identifier: MIT
program test_internal_read_sections
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::head='program p'//nl//'implicit none'//nl// &
        'integer :: a(-1:3),lo,hi,step,ios'//nl//'character(len=40) :: text'//nl
    character(:),allocatable::source
    type(program_t)::p,bad
    type(diagnostic_t)::d
    integer::checks=0,pc,root,bound,k,j
    source=head//'a=8'//nl//'lo=3'//nl//'hi=-1'//nl//'step=-2'//nl//'text="1 2 3"'//nl// &
        'read(text,*,iostat=ios)a(lo:hi:step)'//nl// &
        'if(ios/=0)error stop 1'//nl//'if(any(a/=[3,8,2,8,1]))error stop 2'//nl//'end program'//nl
    call parse(source,p)
    call execute_program(p,d);call check(d%code==0,'descending section values')
    pc=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_internal)pc=j
    end do
    root=p%code(pc)%items(1);bound=p%expressions(root)%left
    call check(valid_internal_read(p,p%code(pc)),'canonical READ accepted')
    do k=1,30
        bad=p
        select case(k)
        case(1);bad%expressions(root)%rank=2
        case(2);bad%expressions(root)%extent=3
        case(3);bad%expressions(root)%dims=[-1_8,0_8,0_8]
        case(4);bad%expressions(root)%real_kind=8
        case(5);bad%expressions(root)%typ=ty_real
        case(6);bad%expressions(root)%parenthesized=.true.
        case(7);bad%expressions(root)%scope=1
        case(8);bad%expressions(root)%character_len=1
        case(9);bad%expressions(root)%third=bound
        case(10);bad%expressions(root)%left2=bound
        case(11);bad%expressions(root)%stride2=bound
        case(12);bad%expressions(root)%triplet(2)=.true.
        case(13);bad%expressions(root)%args=[bound]
        case(14);bad%expressions(root)%op='+'
        case(15);bad%expressions(root)%value%i=1
        case(16);bad%expressions(root)%length_expr=bound
        case(17);bad%expressions(root)%constructor_owner=1
        case(18);bad%expressions(root)%symbol=0
        case(19);bad%expressions(bound)%symbol=5 ! IOSTAT symbol
        case(20);bad%expressions(bound)%typ=ty_real
        case(21);bad%expressions(bound)%real_kind=8
        case(22);bad%expressions(bound)%rank=1
        case(23);bad%expressions(bound)%extent=1
        case(24);bad%expressions(bound)%value%i=1
        case(25);bad%expressions(bound)%args=[bound]
        case(26);bad%expressions(bound)%left=bound
        case(27);bad%expressions(bound)%constructor_kind_expr=1
        case(28);bad%symbols(1)%dummy_intent=1
        case(29);bad%symbols(1)%is_pointer=.true.
        case(30);bad%code(pc)%items=[root,root]
        end select
        call check(.not.valid_internal_read(bad,bad%code(pc)),'metadata mutation refused')
    end do
    call run(head//'a=8'//nl//'text="1 bad"'//nl//'read(text,*,iostat=ios)a(0:2)'//nl// &
        'if(ios<=0)error stop 1'//nl//'if(a(-1)/=8.or.a(3)/=8)error stop 2'//nl//'end program'//nl,.true.)
    call run(head//'a=8'//nl//'text="1"'//nl//'read(text,*,iostat=ios)a(0:2)'//nl// &
        'if(ios>=0)error stop 1'//nl//'if(a(-1)/=8.or.a(3)/=8)error stop 2'//nl//'end program'//nl,.true.)
    call run(head//'a=8'//nl//'text="1,,3"'//nl//'read(text,*,iostat=ios)a(0:2)'//nl// &
        'if(any(a/=[8,1,8,3,8]))error stop 2'//nl//'end program'//nl,.true.)
    call run(head//'a=8'//nl//'text="1 /"'//nl//'read(text,*,iostat=ios)a(0:2)'//nl// &
        'if(any(a/=[8,1,8,8,8]))error stop 2'//nl//'end program'//nl,.true.)
    call run(head//'a=8'//nl//'text="bad"'//nl//'read(text,*,iostat=ios)a(0:2)'//nl// &
        'print *,a(0)'//nl//'end program'//nl,.false.)
    call run(head//'a=8'//nl//'step=0'//nl//'text="1"'//nl//'read(text,*,iostat=ios)a(0:2:step)'//nl// &
        'end program'//nl,.false.)
    print *, 'internal READ section author checks:',checks
contains
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *, 'FAIL: ',label
            if(allocated(d%message))print *,d%message
            error stop 1
        end if
        checks=checks+1
    end subroutine
    subroutine parse(source,prog)
        character(*),intent(in)::source
        type(program_t),intent(out)::prog
        d=diagnostic_t();call parse_subset(source,prog,d)
        if(d%code==0)call verify_frontend(source,prog,d)
        call check(d%code==0,'parse/frontend')
    end subroutine
    subroutine run(source,success)
        character(*),intent(in)::source
        logical,intent(in)::success
        type(program_t)::q
        call parse(source,q);call execute_program(q,d)
        call check((d%code==0).eqv.success,'transfer outcome')
    end subroutine
end program
