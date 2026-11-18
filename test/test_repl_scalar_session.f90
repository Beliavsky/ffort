! SPDX-License-Identifier: MIT
program test_repl_scalar_session
    use, intrinsic :: iso_fortran_env, only:int64,real64
    use fi_ir
    use fi_parser, only:parse_subset
    use fi_runtime, only:scalar_session_t,reset_scalar_session,execute_scalar_session, &
        inspect_scalar_session,scalar_session_frontier,scalar_session_tainted, &
        validate_scalar_session_program,validate_scalar_session_query
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::head='program p'//nl//'implicit none'//nl//'integer::i,z'//nl//'real::x'//nl
    type(scalar_session_t)::session,other
    type(program_t)::p,q,bad
    type(diagnostic_t)::d
    type(value_t)::v,w
    logical::defined
    integer::checks,j,oldpc,oldne,lit
    checks=0
    call parse(head//'i=1'//nl,p)
    call execute_scalar_session(session,p,d);call expect(d%code==0,'first execution')
    call inspect_scalar_session(session,1,v,defined,d)
    call expect(defined.and.v%i==1_int64,'retained initial scalar')
    call inspect_scalar_session(session,2,v,defined,d);call expect(.not.defined,'undefined retained')
    oldpc=scalar_session_frontier(session);oldne=p%ne
    call parse(head//'i=1'//nl//'i=i+2'//nl,q)
    call execute_scalar_session(session,q,d);call expect(d%code==0,'suffix execution')
    call inspect_scalar_session(session,1,v,defined,d);call expect(defined.and.v%i==3,'suffix not replay')
    call execute_scalar_session(session,q,d);call expect(d%code==0,'empty suffix')
    call inspect_scalar_session(session,1,v,defined,d);call expect(v%i==3,'empty suffix unchanged')
    oldpc=scalar_session_frontier(session)
    call parse(head//'i=1'//nl//'i=i+2'//nl//'print *, i'//nl,p)
    call validate_scalar_session_query(p,q%nc,d);call expect(d%code==0,'query admission')
    call execute_scalar_session(session,p,d,commit=.false.);call expect(d%code==0,'query execution')
    call expect(scalar_session_frontier(session)==oldpc,'query uncommitted')
    call execute_scalar_session(session,p,d,commit=.false.);call expect(d%code==0,'repeat query')
    call expect(scalar_session_frontier(session)==oldpc,'repeat query frontier')
    ! Exact prefix/declaration changes reject without taint or mutation.
    bad=p;bad%symbols(1)%real_kind=8;call reject(bad,'changed declaration')
    bad=p;bad%code(1)%op=op_random_seed;call reject(bad,'changed old opcode')
    bad=p;bad%expressions(1)%value%i=17;call reject(bad,'changed old literal')
    bad=p;bad%expressions(bad%ne)%kind=ex_call;call reject(bad,'hidden call')
    bad=p;bad%expressions(bad%ne)%rank=1;call reject(bad,'rank metadata')
    bad=p;bad%code(bad%nc)%advance_mode=1;call reject(bad,'nonadvancing output')
    bad=p;allocate(bad%expressions(bad%ne)%args(0));call reject(bad,'inactive args')
    bad=p;bad%expressions(bad%ne)%kind=ex_binary;bad%expressions(bad%ne)%left=bad%ne
    bad%expressions(bad%ne)%right=bad%ne;bad%expressions(bad%ne)%op='+'
    call reject(bad,'cyclic expression')
    bad=p;bad%code(bad%nc)%items=[p%code(p%nc)%items(1),p%code(p%nc)%items(1)]
    call reject(bad,'multiple query items')
    bad=p;bad%code(bad%nc)%format='(I0)';call reject(bad,'formatted query')
    bad=p;deallocate(bad%symbols);allocate(bad%symbols(0:size(p%symbols)-1))
    bad%symbols=p%symbols;call reject(bad,'shifted symbol lower bound')
    bad=p;deallocate(bad%expressions);allocate(bad%expressions(0:size(p%expressions)-1))
    bad%expressions=p%expressions;call reject(bad,'shifted expression lower bound')
    bad=p;deallocate(bad%code);allocate(bad%code(0:size(p%code)-1))
    bad%code=p%code;call reject(bad,'shifted instruction lower bound')
    bad=p;deallocate(bad%code(bad%nc)%items);allocate(bad%code(bad%nc)%items(0:0))
    bad%code(bad%nc)%items(0)=p%code(p%nc)%items(1);call reject(bad,'shifted item lower bound')
    bad=p;deallocate(bad%symbols);allocate(bad%symbols(max_symbols+1))
    call reject(bad,'excess symbol capacity')
    bad=p;deallocate(bad%expressions);allocate(bad%expressions(max_expressions+1))
    call reject(bad,'excess expression capacity')
    bad=p;deallocate(bad%code);allocate(bad%code(max_instructions+1))
    call reject(bad,'excess instruction capacity')
    d=diagnostic_t();call execute_scalar_session(session,p,d,max_steps=0_int64)
    call expect(d%code/=0,'nonpositive budget rejected')
    d=diagnostic_t();call execute_scalar_session(other,p,d,commit=.false.)
    call expect(d%code/=0.and..not.scalar_session_tainted(other),'fresh query rejected without taint')
    call expect(.not.scalar_session_tainted(session),'admission rejection does not taint')
    d=diagnostic_t();call inspect_scalar_session(session,1,v,defined,d)
    call expect(defined.and.v%i==3,'rejected requests preserve values')
    ! Runtime failure taints, and cannot be resumed even using unchanged old code.
    call parse(head//'i=1'//nl//'i=i+2'//nl//'z=0'//nl//'i=1/z'//nl,p)
    call execute_scalar_session(session,p,d);call expect(d%code/=0,'division failure')
    call expect(scalar_session_tainted(session),'runtime failure taints')
    d=diagnostic_t();call execute_scalar_session(session,q,d);call expect(d%code/=0,'taint refuses retry')
    call reset_scalar_session(session);call expect(.not.scalar_session_tainted(session),'reset clears taint')
    ! RNG continues across suffixes and readonly queries.
    call parse(head//'call random_seed()'//nl//'call random_number(x)'//nl,p)
    d=diagnostic_t();call execute_scalar_session(session,p,d);call expect(d%code==0,'RNG initial')
    call parse(head//'call random_seed()'//nl//'call random_number(x)'//nl//'print *, x'//nl,q)
    call execute_scalar_session(session,q,d,commit=.false.);call expect(d%code==0,'RNG readonly query')
    call parse(head//'call random_seed()'//nl//'call random_number(x)'//nl//'call random_number(x)'//nl,q)
    call execute_scalar_session(session,q,d);call expect(d%code==0,'RNG suffix')
    call inspect_scalar_session(session,3,v,defined,d)
    call execute_scalar_session(other,q,d);call expect(d%code==0,'RNG one-pass baseline')
    call inspect_scalar_session(other,3,w,defined,d)
    call expect(transfer(v%r,0_int64)==transfer(w%r,0_int64),'RNG matches no-replay baseline')
    call reset_scalar_session(session)
    call parse('program p'//nl//'implicit none'//nl,p)
    call execute_scalar_session(session,p,d);call expect(d%code==0,'empty declaration universe')
    ! Deferred-length strings compare exact lengths, not blank-padded equality.
    call reset_scalar_session(session)
    call parse('program p'//nl//'implicit none'//nl//'print "(A)", "x"'//nl,p)
    call execute_scalar_session(session,p,d);call expect(d%code==0,'format prefix baseline')
    bad=p;bad%code(1)%format=p%code(1)%format//' '
    d=diagnostic_t();call execute_scalar_session(session,bad,d)
    call expect(d%code/=0,'changed old format trailing length')
    bad=p
    do j=1,bad%ne
        if(bad%expressions(j)%kind/=ex_literal)cycle
        if(bad%expressions(j)%typ/=ty_character)cycle
        bad%expressions(j)%value%s=bad%expressions(j)%value%s//' '
        bad%expressions(j)%character_len=bad%expressions(j)%character_len+1
        exit
    end do
    call expect(j<=bad%ne,'character literal mutation found')
    d=diagnostic_t();call execute_scalar_session(session,bad,d)
    call expect(d%code/=0,'changed old string trailing length')
    call expect(.not.scalar_session_tainted(session),'string prefix rejection does not taint')
    ! Admission boundary: 256 * 65536 bytes = exactly 16 MiB.
    p=program_t();p%name='budget';p%ne=256
    allocate(p%symbols(1),p%expressions(257),p%code(1))
    do j=1,257
        p%expressions(j)%kind=ex_literal;p%expressions(j)%typ=ty_character
        p%expressions(j)%real_kind=4;p%expressions(j)%character_len=65536
        p%expressions(j)%value=value_t(tag=ty_character,real_kind=4)
        p%expressions(j)%value%s=repeat('x',65536)
    end do
    d=diagnostic_t();call validate_scalar_session_program(p,d)
    call expect(d%code==0,'exact 16 MiB literal budget admitted')
    p%ne=257;p%expressions(257)%value%s='x';p%expressions(257)%character_len=1
    d=diagnostic_t();call validate_scalar_session_program(p,d)
    call expect(d%code/=0,'literal byte over budget rejected')
    p%ne=256;p%ns=1;p%symbols(1)%name='c';p%symbols(1)%typ=ty_character
    p%symbols(1)%character_len=1;p%symbols(1)%real_kind=4
    d=diagnostic_t();call validate_scalar_session_program(p,d)
    call expect(d%code/=0,'scalar storage counts against budget')
    p%ns=0;p%nc=1;p%code(1)%op=op_print;p%code(1)%items=[1];p%code(1)%format='(A)'
    d=diagnostic_t();call validate_scalar_session_program(p,d)
    call expect(d%code/=0,'format bytes count against budget')
    ! Inactive slots are neither admitted expressions nor retained snapshot data.
    call reset_scalar_session(session)
    call parse('program p'//nl//'implicit none'//nl,p)
    p%expressions(1)%kind=ex_binary;p%expressions(1)%left=1
    p%expressions(1)%value%s=repeat('x',65537)
    p%code(1)%format=repeat('x',65537)
    allocate(p%procedures(1)%args(5));p%procedures(1)%args=-1
    call execute_scalar_session(session,p,d)
    call expect(d%code==0,'inactive cyclic oversized payload ignored')
    call execute_scalar_session(session,p,d)
    call expect(d%code==0,'inactive payload not part of retained prefix')
    call intrinsic_checks()
    call conditional_checks()
    print *, 'scalar session checks: ',checks
contains
    subroutine conditional_checks()
        character(:),allocatable::source
        integer::a,branch,jump,oldfrontier
        source=head//'i=0'//nl//'if (.false.) then'//nl//'i=z'//nl// &
            'else if (.true.) then'//nl//'if (.true.) i=7'//nl//'else'//nl//'i=9'//nl//'endif'//nl
        call reset_scalar_session(session)
        call parse(source,p)
        call execute_scalar_session(session,p,d)
        call expect(d%code==0,'nested conditional executes')
        call inspect_scalar_session(session,1,v,defined,d)
        call expect(defined.and.v%i==7,'skipped undefined and selected ELSEIF')
        oldfrontier=scalar_session_frontier(session)
        call parse(source//'print *, i'//nl,q)
        call validate_scalar_session_query(q,p%nc,d)
        call expect(d%code==0,'query after closed conditional')
        call execute_scalar_session(session,q,d,commit=.false.)
        call expect(d%code==0.and.scalar_session_frontier(session)==oldfrontier,'query retains frontier')
        call execute_scalar_session(session,q,d,commit=.false.)
        call expect(d%code==0.and.scalar_session_frontier(session)==oldfrontier,'repeated query retains frontier')
        call parse(source//'if (i==7) then'//nl//'i=i+1'//nl//'end if'//nl,q)
        call execute_scalar_session(session,q,d)
        call inspect_scalar_session(session,1,v,defined,d)
        call expect(d%code==0.and.defined.and.v%i==8,'appended IF stable prefix and no replay')
        call execute_scalar_session(session,q,d)
        call inspect_scalar_session(session,1,v,defined,d)
        call expect(d%code==0.and.v%i==8,'empty suffix does not replay IF')
        branch=0;jump=0
        do a=1,p%nc
            if(p%code(a)%op==op_branch)branch=a
            if(p%code(a)%op==op_jump)jump=a
        end do
        call expect(branch>0.and.jump>0,'conditional fixture opcodes')
        do a=1,12
            bad=p
            select case(a)
            case(1);bad%code(branch)%target=branch
            case(2);bad%code(branch)%target=1
            case(3);bad%code(branch)%target=bad%nc+2
            case(4);bad%code(branch)%a=0
            case(5);bad%code(branch)%a=bad%ne+1
            case(6);bad%code(branch)%a=bad%code(1)%a
            case(7);bad%code(branch)%symbol=1
            case(8);bad%code(jump)%target=jump
            case(9);bad%code(jump)%target=1
            case(10);bad%code(jump)%target=bad%nc+2
            case(11);bad%code(jump)%a=1
            case(12);bad%code(jump)%op=op_do
            end select
            d=diagnostic_t();call validate_scalar_session_program(bad,d)
            call expect(d%code/=0,'conditional forged IR rejected')
        end do
        ! Rejection before execution preserves session even if a prefix would print.
        bad=q;bad%code(bad%nc-1)%target=1
        d=diagnostic_t();call execute_scalar_session(session,bad,d)
        call expect(d%code/=0.and..not.scalar_session_tainted(session),'back edge rejected before effects')
        call parse(source//'print *, i'//nl,q)
        bad=q;bad%code(branch)%target=bad%nc+1
        d=diagnostic_t();call validate_scalar_session_query(bad,p%nc,d)
        call expect(d%code/=0,'query bypass rejected')
        call reset_scalar_session(session)
        call parse(head//'i=1'//nl//'if (.true.) then'//nl//'else'//nl//'endif'//nl,p)
        call execute_scalar_session(session,p,d)
        call expect(d%code==0,'empty IF arms')
        call reset_scalar_session(session)
        call parse(head//'if (.true.) i=z'//nl,p)
        call execute_scalar_session(session,p,d)
        call expect(d%code/=0.and.scalar_session_tainted(session),'taken undefined arm taints')
    end subroutine
    subroutine intrinsic_checks()
        character(5),parameter::names(7)=[character(5)::'abs','sqrt','sin','cos','exp','log','log10']
        real(real64),parameter::expected(7)=[1.0_real64,1.0_real64,sin(1.0_real64), &
            cos(1.0_real64),exp(1.0_real64),0.0_real64,0.0_real64]
        character(23),parameter::failures(5)=[character(23):: &
            'sqrt(-1.0)','log(0.0)','log10(-1.0)','exp(1000.0)','abs(-2147483647-1)']
        integer::a,b,c,rk
        character(1)::ks
        do rk=4,8,4
            write(ks,'(I1)')rk
            do a=1,size(names)
                call reset_scalar_session(session)
                call parse('program p'//nl//'implicit none'//nl//'real('//ks//')::x'//nl// &
                    'x='//trim(names(a))//'(1.0_'//ks//')'//nl,p)
                call execute_scalar_session(session,p,d)
                call expect(d%code==0,'unary intrinsic execution '//trim(names(a))//ks)
                call inspect_scalar_session(session,1,v,defined,d)
                call expect(defined.and.v%tag==ty_real.and.v%real_kind==rk,'intrinsic result kind')
                call expect(abs(v%r-expected(a))<1.0e-6_real64,'intrinsic numerical result')
            end do
            call reset_scalar_session(session)
            call parse('program p'//nl//'implicit none'//nl//'integer('//ks//')::i'//nl// &
                'i=abs(-7_'//ks//')'//nl,p)
            call execute_scalar_session(session,p,d)
            call inspect_scalar_session(session,1,v,defined,d)
            call expect(d%code==0.and.defined.and.v%i==7,'integer ABS')
        end do
        call reset_scalar_session(session)
        call parse(head//'x=sqrt(abs(-4.0))'//nl,p)
        call execute_scalar_session(session,p,d)
        call inspect_scalar_session(session,3,v,defined,d)
        call expect(d%code==0.and.defined.and.v%r==2.0,'nested intrinsics')
        b=p%ne
        call expect(p%expressions(b)%kind==ex_call,'intrinsic fixture')
        do a=1,19
            bad=p
            associate(e=>bad%expressions(b))
            select case(a)
            case(1);deallocate(e%args)
            case(2);deallocate(e%args);allocate(e%args(0))
            case(3);deallocate(e%args);allocate(e%args(2));e%args=1
            case(4);deallocate(e%args);allocate(e%args(0:0));e%args=1
            case(5);e%args(1)=0
            case(6);e%args(1)=b
            case(7);e%args(1)=b+1
            case(8);e%typ=ty_integer
            case(9);e%real_kind=8
            case(10);e%rank=1
            case(11);e%extent=1
            case(12);e%intrinsic_mask=1
            case(13);e%bound_binding=1
            case(14);e%symbol=1
            case(15);e%left=1
            case(16);e%op='random_number'
            case(17);e%kind=ex_user_call
            case(18);e%value%i=1
            case(19);e%generic_id=1
            end select
            end associate
            d=diagnostic_t();call validate_scalar_session_program(bad,d)
            call expect(d%code/=0,'forged intrinsic metadata rejected')
        end do
        bad=p;c=bad%expressions(b)%args(1);bad%expressions(c)%kind=ex_user_call
        d=diagnostic_t();call validate_scalar_session_program(bad,d)
        call expect(d%code/=0,'nested user call rejected')
        do a=1,size(failures)
            call reset_scalar_session(session)
            call parse(head//'x='//trim(failures(a))//nl,p)
            call execute_scalar_session(session,p,d)
            call expect(d%code/=0.and.scalar_session_tainted(session),'domain/overflow failure taints')
            d=diagnostic_t();call execute_scalar_session(session,p,d)
            call expect(d%code/=0,'runtime failure not retried')
        end do
    end subroutine
    subroutine parse(source,prog)
        character(*),intent(in)::source
        type(program_t),intent(out)::prog
        d=diagnostic_t();call parse_subset(source//'end program'//nl,prog,d)
        call expect(d%code==0,'fixture parse')
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *, 'FAIL ',label
            if(allocated(d%message))print *,d%message
            stop 1
        end if
        checks=checks+1
    end subroutine
    subroutine reject(prog,label)
        type(program_t),intent(in)::prog
        character(*),intent(in)::label
        d=diagnostic_t();call execute_scalar_session(session,prog,d,commit=.false.)
        call expect(d%code/=0,label)
    end subroutine
end program
