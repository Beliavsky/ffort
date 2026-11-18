! SPDX-License-Identifier: MIT
program test_constructor_implied_do_adapter
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::i,j,k,a(8)'//nl//'i=77'//nl//'j=88'//nl// &
        'a=[0,((10*i+j,j=1,i),i=1,3),9]'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::checks,n,outer,inner,oi,ii,alternate,wrapper,which,bound
    character(:),allocatable::changed
    checks=0;outer=0;inner=0;oi=0;ii=0;alternate=0;wrapper=0
    call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
    call verify_frontend(source,p,d);call expect(d%code==0,'baseline adapter')
    do n=1,p%ns
        if(p%symbols(n)%name=='k') alternate=n
    end do
    do n=1,p%ne
        if(p%expressions(n)%kind==ex_constructor_do) then
            if(p%symbols(p%expressions(n)%symbol)%name=='i') outer=n
            if(p%symbols(p%expressions(n)%symbol)%name=='j') inner=n
        end if
        if(p%expressions(n)%kind==ex_constructor) wrapper=n
    end do
    do n=1,p%ne
        if(p%expressions(n)%kind/=ex_constructor_index) cycle
        if(p%expressions(n)%constructor_owner==outer) oi=n
        if(p%expressions(n)%constructor_owner==inner) ii=n
    end do
    call expect(min(outer,inner,oi,ii,alternate,wrapper)>0,'identities')
    bound=p%expressions(outer)%right
    do which=1,43
        q=p
        select case(which)
        case(1);q%expressions(outer)%line=q%expressions(outer)%line+1
        case(2);q%expressions(outer)%column=q%expressions(outer)%column+1
        case(3);q%expressions(inner)%line=q%expressions(inner)%line+1
        case(4);q%expressions(inner)%column=q%expressions(inner)%column+1
        case(5);q%expressions(outer)%scope=-1
        case(6);q%expressions(outer)%typ=ty_real
        case(7);q%expressions(outer)%real_kind=8
        case(8);q%expressions(outer)%rank=0
        case(9);q%expressions(outer)%extent=0
        case(10);q%expressions(outer)%dims(1)=1
        case(11);q%expressions(outer)%character_len=1
        case(12);q%expressions(outer)%length_expr=bound
        case(13);q%expressions(outer)%constructor_kind_expr=bound
        case(14);q%expressions(outer)%constructor_owner=outer
        case(15);q%expressions(outer)%generic_id=1
        case(16);q%expressions(outer)%bound_type=1
        case(17);q%expressions(outer)%intrinsic_mask=1
        case(18);q%expressions(outer)%parenthesized=.true.
        case(19);q%expressions(outer)%op='character'
        case(20);q%expressions(outer)%value%tag=ty_integer
        case(21);q%expressions(outer)%value%i=1
        case(22);q%expressions(outer)%left2=bound
        case(23);q%expressions(outer)%right2=bound
        case(24);q%expressions(outer)%stride3=bound
        case(25);q%expressions(outer)%args=[outer]
        case(26);q%expressions(outer)%args=[integer::]
        case(27);q%expressions(outer)%left=0
        case(28);q%expressions(outer)%right=0
        case(29);q%expressions(outer)%stride=bound
        case(30);q%expressions(bound)%value%i=4
        case(31);q%expressions(oi)%constructor_owner=inner
        case(32);q%expressions(ii)%constructor_owner=outer
        case(33);q%expressions(oi)%constructor_owner=0
        case(34);q%expressions(oi)%symbol=alternate
        case(35);q%expressions(oi)%kind=ex_variable;q%expressions(oi)%constructor_owner=0
        case(36);q%expressions(ii)%kind=ex_variable;q%expressions(ii)%constructor_owner=0
        case(37);q%expressions(oi)%real_kind=8
        case(38);q%expressions(bound)%constructor_owner=outer
        case(39);q%expressions(wrapper)%args=q%expressions(wrapper)%args(3:1:-1)
        case(40);q%expressions(inner)%symbol=q%expressions(outer)%symbol
        case(41)
            q%expressions(outer)%symbol=alternate
            do n=1,q%ne
                if(q%expressions(n)%kind==ex_constructor_index.and.q%expressions(n)%constructor_owner==outer) &
                    q%expressions(n)%symbol=alternate
            end do
            call expect(valid_constructor_tree(q,wrapper),'coherent alternate declaration remains structurally valid')
        case(42);q%expressions(wrapper)%extent=8
        case(43);q%expressions(oi)%left=bound
        end select
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code/=0,'mutated descriptor rejected by source adapter')
    end do
    changed=source
    n=index(changed,'i=1,3');changed(n:n+4)='i=1,4'
    d=diagnostic_t();call verify_frontend(changed,p,d)
    call expect(d%code/=0,'changed source control rejected')
    changed=source
    n=index(changed,'10*i+j');changed(n:n+5)='10*j+i'
    d=diagnostic_t();call verify_frontend(changed,p,d)
    call expect(d%code/=0,'changed source index association rejected')
    write(error_unit,'(a,i0,a)') 'constructor implied-DO adapter: ',checks,' checks passed'
contains
    subroutine expect(ok,message)
        logical,intent(in)::ok
        character(*),intent(in)::message
        checks=checks+1
        if(ok) return
        write(error_unit,'(a,i0,2a)') 'FAIL mutation ',which,': ',message
        if(allocated(d%message)) write(error_unit,'(a)') d%message
        stop 1
    end subroutine
end program
