! SPDX-License-Identifier: MIT
program test_pointer_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'integer,target::a(2,2)'//nl// &
      'integer,pointer::p(:),q(:)'//nl//'a=0'//nl//'a(:,2)=[3,4]'//nl// &
      'p=>a(:,2)'//nl//'q=>p'//nl//'if(.not.associated(q)) error stop 1'//nl// &
      'p(1)=9'//nl//'if(a(1,2)/=9.or.q(1)/=9) error stop 2'//nl// &
      'nullify(q)'//nl//'if(associated(q)) error stop 3'//nl//'q=>null()'//nl//'end'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,ps,ts,pc,npc,a
    call fresh()
    call verify_frontend(source,p,d)
    call ok('baseline adapter')
    do i=1,3
        call execute_program(p,d)
        call ok('repeated runtime')
    end do
    do i=1,12
        call fresh()
        ps=0;ts=0;pc=0;npc=0
        do j=1,p%ns
            if(p%symbols(j)%name=='p') ps=j
            if(p%symbols(j)%name=='a') ts=j
        end do
        do j=1,p%nc
            if(p%code(j)%op==op_pointer_assign.and.pc==0) pc=j
            if(p%code(j)%op==op_nullify) npc=j
        end do
        a=p%code(pc)%a
        select case(i)
        case(1);p%symbols(ps)%is_pointer=.false.
        case(2);p%symbols(ts)%is_target=.false.
        case(3);p%symbols(ps)%is_target=.true.
        case(4);p%symbols(ps)%is_allocatable=.true.
        case(5);p%symbols(ps)%assumed_shape=.true.
        case(6);p%symbols(ps)%lower_bound=2
        case(7);p%code(pc)%op=op_assign
        case(8);p%code(pc)%b=a
        case(9);p%code(npc)%a=a
        case(10);p%expressions(a)%parenthesized=.true.
        case(11);p%expressions(a)%real_kind=8
        case(12);p%code(pc)%symbol=ts
        end select
        call verify_frontend(source,p,d)
        if(d%code/=1) then
            print *,i,d%code
            error stop 'forged POINTER IR escaped adapter'
        end if
    end do
    call context_mutation('print *,p')
    call context_mutation('print *,p(1)')
    call context_mutation('print *,p(:)')
    call context_mutation('print *,size(p)')
    call context_mutation('print *,lbound(p,1)')
    call context_mutation('print *,kind(p)')
    call context_mutation('print *,shape(p)')
    call context_mutation('if(sum(p)>0) stop')
    call context_mutation('print *,a(:size(p))')
    call context_mutation('print *,a(:p(1))')
    call context_mutation('print *,a(::sum(p))')
    call context_mutation('call consume(p)')
    call context_mutation('call consume(p+1)')
    print '(a)','PASS: pointer SOURCE/AST/IR, aliases, 12 metadata and 26 procedure-context mutations'
contains
    subroutine context_mutation(body)
        character(*),intent(in)::body
        character(:),allocatable::plain,pointer_source
        integer::k,s
        plain='module m'//nl//'contains'//nl//'subroutine inspect(p)'//nl// &
          'integer,intent(in)::p(:)'//nl//'integer::a(4)'//nl//body//nl// &
          'end subroutine'//nl//'subroutine consume(x)'//nl//'integer,intent(in)::x(:)'//nl// &
          'end subroutine'//nl//'end module'//nl//'program main'//nl//'integer::i'//nl//'i=1'//nl//'end'
        d=diagnostic_t();call parse_subset(plain,p,d);call ok('context ordinary parse')
        call verify_frontend(plain,p,d);call ok('context ordinary adapter')
        s=0
        do k=1,p%ns
            if(p%symbols(k)%name=='p') s=k
        end do
        if(s==0) error stop 'context dummy missing'
        ! Independently introduce a POINTER declaration in SOURCE and IR. The
        ! source recognizer is deliberately not rerun: the adapter must enforce
        ! the procedure-data boundary even for unreachable procedure bodies.
        p%symbols(s)%is_pointer=.true.;p%symbols(s)%assumed_shape=.false.
        k=index(plain,'integer,intent(in)::p(:)')
        pointer_source=plain(:k-1)//'integer,pointer,intent(in)::p(:)'// &
            plain(k+len('integer,intent(in)::p(:)'):)
        d=diagnostic_t();call verify_frontend(pointer_source,p,d)
        if(d%code/=1) then
            print *,body,d%code
            error stop 'procedure pointer use escaped independent adapter'
        end if
        ! A forged expression-scope cache must not turn procedure operands into
        ! main-program data accesses. Source/binding scope remains authoritative.
        do k=1,p%ne
            p%expressions(k)%scope=0
        end do
        d=diagnostic_t();call verify_frontend(pointer_source,p,d)
        if(d%code/=1) then
            print *,body,d%code
            error stop 'forged scope bypassed procedure pointer boundary'
        end if
    end subroutine
    subroutine fresh()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        call ok('baseline parse')
    end subroutine
    subroutine ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'pointer frontend test failed'
    end subroutine
end program
