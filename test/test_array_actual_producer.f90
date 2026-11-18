! SPDX-License-Identifier: MIT
! Exercise the actual strict producer, including type/rank metadata and errors.
program test_array_actual_producer
    use fortfront_compiler
    use fortfront_ast, only: subroutine_call_node
    use type_system_unified, only: TREAL, TINT, TLOGICAL
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::i,found
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call check('x**2','real(dp)',':',1,8,.true.)
    call check('x**2_8','real(dp)',':',1,8,.true.)
    call check('-x','real(dp)',':',1,8,.true.)
    call check('x*2','real(dp)',':',1,8,.true.)
    call check('x+2','real(dp)',':',1,8,.true.)
    call check('x*x','real(dp)',':',1,8,.true.)
    call check('x**2+1','real(dp)',':',1,8,.true.)
    call check('(x+1)**2','real(dp)',':',1,8,.true.)
    call check('x(1:-2:-2)**2','real(dp)',':',1,8,.true.)
    call check('2**x','real(dp)',':',1,8,.true.)
    call check('abs(x)','real(dp)',':',1,8,.true.)
    call check('sqrt(x**2)','real(dp)',':',1,8,.true.)
    call check('a**2','real(dp)',':,:',2,8,.true.)
    call check('a(:,1)+1','real(dp)',':',1,8,.true.)
    call check('a(1,:)**2','real(dp)',':',1,8,.true.)
    call check('z**2','real(dp)',':',1,8,.true.)
    call check('s**2.0_8','real(dp)',':',1,8,.true.)
    call check('s**2_8','real',':',1,4,.true.)
    call check('x>0','logical',':',1,4,.true.)
    call check('x**2','real',':',1,4,.false.)
    call check('x+2','real',':',1,4,.false.)
    call check('-x','real',':',1,4,.false.)
    call check('x*x','real',':',1,4,.false.)
    call check('x**2','integer',':',1,4,.false.)
    call check('x**2','real(dp)',':,:',2,8,.false.)
    call check('a**2','real(dp)',':',1,8,.false.)
    call check('x(1)**2','real(dp)',':',1,8,.false.)
    call check('s**2','real(dp)',':',1,8,.false.)
    call check_integer('a+1_8',8,8,.true.)
    call check_integer('a+1',8,8,.true.)
    call check_integer('-a',8,8,.true.)
    call check_integer('a*a',8,8,.true.)
    call check_integer('a(2:1:-1)+1_8',8,8,.true.)
    call check_integer('a+1',4,4,.true.)
    call check_integer('a+1_8',4,8,.true.)
    call check_integer('a**2_8',4,8,.true.)
    call check_integer('a**2',8,8,.true.)
    call check_integer('a+1_8',8,4,.false.)
    call check_integer('a+1',4,8,.false.)
    call check_integer('a**2_8',4,4,.false.)
    call check_integer('a**2',8,4,.false.)
    call check_integer('1_8',8,4,.false.,.true.)
    call check_integer('1',4,8,.false.,.true.)
    print '(a)','PASS: array expression actual producer types, ranks and strict mismatches'
contains
    subroutine check_integer(expr,actual_kind,dummy_kind,ok,scalar)
        character(*),intent(in)::expr
        integer,intent(in)::actual_kind,dummy_kind
        logical,intent(in)::ok
        logical,intent(in),optional::scalar
        character(1)::ak,dk
        character(:),allocatable::dims
        integer::expected_rank
        write(ak,'(I1)') actual_kind
        write(dk,'(I1)') dummy_kind
        dims='(:)';expected_rank=1
        if(present(scalar)) then
            if(scalar) then
                dims='';expected_rank=0
            end if
        end if
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'integer('//ak//'),parameter::a(2)=[1_'//ak//',2_'//ak//']'//nl// &
            'call take('//expr//')'//nl//'contains'//nl// &
            'subroutine take(y)'//nl//'integer('//dk//'),intent(in)::y'//dims//nl// &
            'end subroutine'//nl//'end program',front,opts)
        if(front%success().neqv.ok) then
            print *,expr,actual_kind,dummy_kind
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'unexpected strict integer expression validation'
        end if
        if(.not.ok) then
            if(.not.allocated(front%error_msg)) error stop 'missing integer mismatch'
            if(index(front%error_msg,'Type mismatch in call')==0) &
                error stop 'wrong integer mismatch diagnostic'
            return
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(subroutine_call_node)
                if(node%name/='take') cycle
                typ=query_resolved_type(front%arena,node%arg_indices(1))
                if(.not.typ%found.or.typ%rank/=expected_rank.or. &
                    typ%kind_value/=dummy_kind.or.typ%type_kind/=TINT) &
                    error stop 'integer expression metadata disagrees'
                found=found+1
            end select
        end do
        if(found/=1) error stop 'missing integer expression test target'
    end subroutine
    subroutine check(expr,dummy_type,dims,rank,kind,ok)
        character(*),intent(in)::expr,dummy_type,dims
        integer,intent(in)::rank,kind
        logical,intent(in)::ok
        integer::want_type
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'integer,parameter::dp=kind(1d0)'//nl// &
            'real(dp)::x(-2:1),a(2,2),z(0)'//nl//'real::s(4)'//nl// &
            'call take('//expr//')'//nl//'contains'//nl// &
            'subroutine take(y)'//nl//dummy_type//',intent(in)::y('//dims//')'//nl// &
            'end subroutine'//nl//'end program',front,opts)
        if(front%success().neqv.ok) then
            print *,expr, dummy_type, dims
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'unexpected strict array expression validation'
        end if
        if(.not.ok) then
            if(.not.allocated(front%error_msg)) error stop 'missing mismatch diagnostic'
            if(index(front%error_msg,'Type mismatch in call')==0) &
                error stop 'wrong mismatch diagnostic'
            return
        end if
        want_type=TREAL
        if(dummy_type=='logical') want_type=TLOGICAL
        if(dummy_type=='integer') want_type=TINT
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(subroutine_call_node)
                if(node%name/='take') cycle
                typ=query_resolved_type(front%arena,node%arg_indices(1))
                if(.not.typ%found.or.typ%rank/=rank.or.typ%kind_value/=kind.or. &
                   typ%type_kind/=want_type) then
                    print *,expr,typ%found,typ%rank,typ%kind_value,typ%type_kind
                    error stop 'array expression metadata disagrees'
                end if
                found=found+1
            end select
        end do
        if(found/=1) error stop 'missing actual expression metadata target'
    end subroutine
end program
