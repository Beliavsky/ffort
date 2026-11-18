! SPDX-License-Identifier: MIT
program test_output_implied_do
    use, intrinsic :: iso_fortran_env, only: output_unit,error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(80)::text'//nl//'integer::i,j,k'//nl// &
        'write(text,"(*(i0,1x))") ((10*i+j,j=1,i),i=1,3),i,j'//nl// &
        'if(trim(text)/="11 21 22 31 32 33 4 4") stop 1'//nl// &
        'if(i/=4.or.j/=4) stop 2'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::pc,root,child,s,j,which,checks,ios,alternate
    character(80)::line
    character(:),allocatable::changed
    checks=0;which=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parser')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'baseline adapter')
    pc=0;alternate=0
    do j=1,p%nc
        if(p%code(j)%op==op_write_internal) pc=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='k') alternate=j
    end do
    call expect(pc>0.and.alternate>0,'baseline identities')
    root=p%code(pc)%items(1);s=p%expressions(root)%symbol;child=p%expressions(root)%args(1)
    call expect(valid_output_do(p,root),'baseline public gate')
    do j=1,2
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'repeat independent execution')
    end do
    do which=1,45
        q=p
        select case(which)
        case(1);q%expressions(root)%scope=-1
        case(2);q%expressions(root)%typ=ty_real
        case(3);q%expressions(root)%real_kind=8
        case(4);q%expressions(root)%rank=1
        case(5);q%expressions(root)%extent=1
        case(6);q%expressions(root)%dims(1)=1
        case(7);q%expressions(root)%character_len=0
        case(8);q%expressions(root)%length_expr=1
        case(9);q%expressions(root)%constructor_kind_expr=1
        case(10);q%expressions(root)%generic_id=1
        case(11);q%expressions(root)%bound_type=1
        case(12);q%expressions(root)%bound_binding=1
        case(13);q%expressions(root)%intrinsic_mask=1
        case(14);q%expressions(root)%parenthesized=.true.
        case(15);q%expressions(root)%op='forged'
        case(16);q%expressions(root)%left2=1
        case(17);q%expressions(root)%right2=1
        case(18);q%expressions(root)%stride2=1
        case(19);q%expressions(root)%left3=1
        case(20);q%expressions(root)%right3=1
        case(21);q%expressions(root)%stride3=1
        case(22);q%expressions(root)%third=1
        case(23);q%expressions(root)%triplet(1)=.false.
        case(24);q%expressions(root)%value%tag=ty_integer
        case(25);q%expressions(root)%value%s='forged'
        case(26);allocate(q%expressions(root)%value%record)
        case(27);q%expressions(root)%symbol=0
        case(28);q%expressions(root)%symbol=q%ns+1
        case(29);deallocate(q%expressions(root)%args)
        case(30);q%expressions(root)%args=[integer::]
        case(31);q%expressions(root)%args=[(child,j=1,65)]
        case(32);q%expressions(root)%args(1)=0
        case(33);q%expressions(root)%args(1)=q%ne+1
        case(34);q%expressions(root)%args(1)=root
        case(35);q%expressions(root)%left=0
        case(36);q%expressions(root)%right=q%ne+1
        case(37);q%expressions(root)%stride=-1
        case(38);q%expressions(root)%left=child
        case(39);q%symbols(s)%is_dummy=.true.
        case(40);q%symbols(s)%is_parameter=.true.
        case(41);q%symbols(s)%is_pointer=.true.
        case(42);q%symbols(s)%is_allocatable=.true.
        case(43);q%symbols(s)%is_optional=.true.
        case(44);q%symbols(s)%is_intrinsic=.true.
        case(45);q%expressions(child)%symbol=s
        end select
        call expect(.not.valid_output_do(q,root),'mutated public gate')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'mutated adapter rejects')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'mutated direct runtime rejects')
        call expect(allocated(d%message),'runtime diagnostic present')
        rewind(output_unit);read(output_unit,'(a)',iostat=ios) line
        call expect(ios<0,'failed output is silent')
    end do
    ! Same-typed alternate identities require source agreement, not just shape.
    q=p;q%expressions(root)%symbol=alternate
    call expect(valid_output_do(q,root),'alternate counter remains structurally valid')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'alternate counter source mismatch')
    q=p;q%expressions(root)%line=q%expressions(root)%line+1
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'source location mismatch')
    q=p;q%expressions(root)%column=q%expressions(root)%column+1
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'source column mismatch')
    q=p;q%expressions(root)%args=[child,child]
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'object count mismatch')
    q=p;q%expressions(root)%stride=q%expressions(root)%left
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'step presence mismatch')
    q=p;q%expressions(q%expressions(child)%args(1))%left=root
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code==2,'control tree cannot be used as arithmetic value')
    changed=source;j=index(changed,'10*i+j');changed(j:j+5)='10*i+k'
    d=diagnostic_t();call verify_frontend(changed,p,d)
    call expect(d%code==1,'different source output object rejected')
    write(error_unit,'(a,i0,a)') 'output implied-DO native: ',checks,' checks passed'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok) return
        write(error_unit,*) 'FAIL ',checks,which,': ',label
        if(allocated(d%message)) write(error_unit,*) d%message
        error stop 1
    end subroutine
end program
