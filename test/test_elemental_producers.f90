! SPDX-License-Identifier: MIT
! Direct producer regression: elemental call shape and declared result type.
program test_elemental_producers
    use fortfront_compiler
    use fortfront_ast, only: call_or_subscript_node
    use ast_nodes_procedure, only: function_def_node
    use type_system_unified, only: mono_type_t, TREAL, TARRAY, TFUN, TDOUBLE, TINT
    implicit none
    character(*), parameter :: nl=new_line('a')
    type(compiler_frontend_options_t) :: opts
    type(compiler_frontend_result_t) :: front
    type(resolved_type_query_t) :: resolved
    type(mono_type_t) :: typ
    integer :: i, rank, counts(0:2), functions
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call compile_frontend_from_string('module m'//nl//'implicit none'//nl//'contains'//nl// &
        'pure elemental real(kind=8) function converted(x,y) result(r)'//nl// &
        'integer,intent(in)::x,y'//nl//'r=real(x+y,kind=8)'//nl//'end function'//nl// &
        'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
        'integer::a(3),b(2,3)'//nl//'real(kind=8)::s,v(3),w(2,3)'//nl// &
        'a=1'//nl//'b=2'//nl//'s=converted(1,2)'//nl// &
        'v=converted(a,2)'//nl//'v=converted(y=a,x=2)'//nl// &
        'w=converted(b,2)'//nl//'w=converted(y=b,x=2)'//nl// &
        's=local(1,2)'//nl//'v=local(a,2)'//nl//'w=local(y=b,x=2)'//nl// &
        'contains'//nl//'elemental real(kind=8) function local(x,y) result(r)'//nl// &
        'integer,intent(in)::x,y'//nl//'r=real(x+y,kind=8)'//nl// &
        'end function'//nl//'end program',front,opts)
    if (.not.front%success()) then
        if (allocated(front%error_msg)) print *,front%error_msg
        error stop 'elemental producer rejected valid input'
    end if
    counts=0
    functions=0
    do i=1,front%arena%entry_count
        if (.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if (node%name/='converted'.and.node%name/='local') cycle
            typ=node%inferred_type
            rank=0
            call typ%sync_from_arena()
            do while(typ%kind==TARRAY)
                rank=rank+1
                typ=typ%get_arg(1)
                call typ%sync_from_arena()
            end do
            if (rank>2) error stop 'unexpected elemental rank'
            if (typ%kind/=TREAL.and.typ%kind/=TDOUBLE) error stop 'elemental result type changed to argument type'
            counts(rank)=counts(rank)+1
            resolved=query_resolved_type(front%arena,i)
            if (.not.resolved%found.or.resolved%rank/=rank.or.resolved%type_kind/=TREAL) &
                error stop 'elemental resolved type mismatch'
            if (resolved%kind_value/=8) error stop 'elemental result kind lost'
        type is(function_def_node)
            functions=functions+1
            typ=node%inferred_type
            if (typ%kind==TFUN) typ=typ%get_arg(2)
            if (typ%kind==TARRAY) error stop 'elemental definition result lifted'
        end select
    end do
    if (any(counts/=[2,3,3])) then
        print *,counts
        error stop 'elemental shape coverage differs'
    end if
    if (functions/=2) error stop 'elemental function coverage differs'
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'real::a(3)'//nl//'integer::b(3)'//nl//'a=1.0'//nl//'b=f(a)'//nl// &
        'contains'//nl//'elemental integer function f(x)'//nl// &
        'integer,intent(in)::x'//nl//'f=x'//nl//'end function'//nl//'end program',front,opts)
    if (front%success()) error stop 'elemental array element type mismatch accepted'
    if (.not.allocated(front%error_msg)) error stop 'elemental mismatch diagnostic absent'
    if (index(front%error_msg,'Type mismatch in call')==0) &
        error stop 'elemental mismatch diagnostic differs'
    call compile_frontend_from_string( &
        'module scalar_ops'//nl// &
        'implicit none'//nl// &
        'private'//nl// &
        'public::scalar_wrap'//nl// &
        'contains'//nl// &
        'pure integer function compute(xx) result(rr)'//nl// &
        'integer,intent(in)::xx'//nl// &
        'rr=xx+100'//nl// &
        'end function'//nl// &
        'pure integer function scalar_wrap(xx) result(rr)'//nl// &
        'integer,intent(in)::xx'//nl// &
        'rr=compute(xx)'//nl// &
        'end function'//nl// &
        'end module'//nl// &
        'module array_ops'//nl// &
        'implicit none'//nl// &
        'private'//nl// &
        'public::array_wrap'//nl// &
        'contains'//nl// &
        'elemental real(8) function compute(xx) result(rr)'//nl// &
        'integer,intent(in)::xx'//nl// &
        'rr=xx*0.5d0'//nl// &
        'end function'//nl// &
        'pure real(8) function array_wrap(xx) result(rr)'//nl// &
        'integer,intent(in)::xx(:)'//nl// &
        'rr=sum(compute(xx))'//nl// &
        'rr=sum(compute(xx+1))'//nl// &
        'rr=sum(compute(xx(::2)))'//nl// &
        'rr=sum(compute(xx=(xx)))'//nl// &
        'rr=sum(compute(xx=abs(xx)))'//nl// &
        'rr=sum(compute(int(real(xx))))'//nl// &
        'rr=sum(compute(max(xx,0)))'//nl// &
        'rr=sum(compute(int(sqrt(real(xx)))))'//nl// &
        'end function'//nl// &
        'end module'//nl// &
        'program elemental_test'//nl// &
        'use scalar_ops, only: scalar_wrap'//nl// &
        'use array_ops, only: array_wrap'//nl// &
        'implicit none'//nl// &
        'integer::aa(3)'//nl// &
        'aa(1)=1'//nl// &
        'aa(2)=2'//nl// &
        'aa(3)=3'//nl// &
        'print *,scalar_wrap(5),array_wrap(aa)'//nl// &
        'end program',front,opts)
    if (.not.front%success()) error stop 'same-named scoped producer source rejected'
    counts=0
    do i=1,front%arena%entry_count
        if (.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if (node%name/='compute') cycle
            resolved=query_resolved_type(front%arena,i)
            if (.not.resolved%found) error stop 'scoped elemental metadata missing'
            typ=node%inferred_type
            call typ%sync_from_arena()
            if (resolved%rank==1) then
                if (typ%kind/=TARRAY) error stop 'scoped elemental array rank lost'
                typ=typ%get_arg(1)
                call typ%sync_from_arena()
                if (typ%kind/=TREAL.and.typ%kind/=TDOUBLE) &
                    error stop 'scoped elemental result contaminated by other module'
                if (resolved%type_kind/=TREAL.or.resolved%kind_value/=8) &
                    error stop 'scoped elemental metadata type/kind mismatch'
                counts(1)=counts(1)+1
            else
                if (resolved%rank/=0.or.resolved%type_kind/=TINT) &
                    error stop 'scoped scalar helper changed'
                counts(0)=counts(0)+1
            end if
        end select
    end do
    if (any(counts/=[1,8,0])) error stop 'scoped private helper coverage differs'
    call compile_frontend_from_string( &
        'program p'//nl// &
        'implicit none'//nl// &
        'integer::a(2,3),d'//nl// &
        'a=1'//nl// &
        'd=2'//nl// &
        'print *,take1(compute(a(:,1)))'//nl// &
        'print *,take2(compute(a))'//nl// &
        'print *,compute(sum(a,dim=1))'//nl// &
        'print *,compute(sum(a,dim=2))'//nl// &
        'print *,compute(sum(dim=d,array=a))'//nl// &
        'print *,compute(sum(a))'//nl// &
        'contains'//nl// &
        'elemental integer function compute(x) result(r)'//nl// &
        'integer,intent(in)::x'//nl// &
        'r=x*x+1'//nl// &
        'end function'//nl// &
        'pure integer function take1(x) result(r)'//nl// &
        'integer,intent(in)::x(:)'//nl// &
        'r=sum(x)'//nl// &
        'end function'//nl// &
        'pure integer function take2(x) result(r)'//nl// &
        'integer,intent(in)::x(:,:)'//nl// &
        'r=sum(x)'//nl// &
        'end function'//nl// &
        'end program',front,opts)
    if (.not.front%success()) then
        if (allocated(front%error_msg)) print *,front%error_msg
        error stop 'elemental assumed-shape/reduction composition rejected'
    end if
    counts=0
    do i=1,front%arena%entry_count
        if (.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if (node%name/='compute') cycle
            resolved=query_resolved_type(front%arena,i)
            if (.not.resolved%found.or.resolved%type_kind/=TINT) &
                error stop 'elemental reduction composition metadata missing'
            if (resolved%rank<0.or.resolved%rank>2) &
                error stop 'elemental reduction composition rank invalid'
            counts(resolved%rank)=counts(resolved%rank)+1
        end select
    end do
    if (any(counts/=[1,4,1])) error stop 'elemental reduction composition ranks differ'
    print '(a)','PASS: ELEMENTAL producer scalar/rank-one/rank-two results and real kind'
end program
