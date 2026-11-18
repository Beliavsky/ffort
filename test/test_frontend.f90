! SPDX-License-Identifier: MIT
program test_frontend
    use fortfront_compiler
    use fi_frontend, only: verify_frontend
    use fi_parser, only: parse_subset
    use fi_ir, only: program_t, diagnostic_t, ty_integer, ex_literal, op_assign
    implicit none
    type(compiler_frontend_result_t) :: result
    type(compiler_frontend_options_t) :: opts
    type(resolved_type_query_t) :: q
    type(declaration_query_t) :: d
    type(program_t) :: p
    type(diagnostic_t) :: diag
    character(*),parameter :: nl=new_line('a')
    character(*),parameter :: source='program p'//nl//'implicit none'//nl// &
        'real :: x'//nl//'character(len=8) :: s'//nl// &
        'character(kind=1,len=8) :: t'//nl//'character(len=8,kind=1) :: u'//nl// &
        'x=1.0'//nl//"s='hello'"//nl//"t='hello'"//nl//"u='hello'"//nl// &
        'print *, x, s, t, u'//nl//'end program p'
    integer :: i,j,found,expected
    opts%operating_mode=OPERATING_MODE_STRICT
    do j=1,7
        opts%input_mode=INPUT_MODE_STANDARD
        opts%standardize=.false.
        if(j==2 .or. j==6) opts%standardize=.true.
        if(j==4 .or. j==7) opts%input_mode=INPUT_MODE_LAZY
        if(j==4) opts%standardize=.true.
        call compile_frontend_from_string(source,result,opts)
        if(.not.result%success()) then
            if(allocated(result%error_msg)) print *,result%error_msg
            error stop 'frontend regression: source rejected'
        end if
        expected=4
        if(opts%input_mode==INPUT_MODE_LAZY) expected=8
        found=0
        do i=1,result%arena%entry_count
            d=query_declaration(result%arena,i)
            if(.not.d%found) cycle
            q=query_resolved_type(result%arena,i)
            if(.not.q%found) error stop 'frontend regression: missing declaration metadata'
            select case(d%name)
            case('x')
                if(q%kind_value/=expected) error stop 'frontend regression: default REAL mode leakage'
                if(q%storage_size_bits/=expected*8) error stop 'frontend regression: REAL storage size'
                found=found+1
            case('s','t','u')
                if(q%kind_value/=1) error stop 'frontend regression: CHARACTER length treated as kind'
                found=found+1
            end select
        end do
        if(found/=4) error stop 'frontend regression: missing declarations'
    end do
    opts%input_mode=INPUT_MODE_STANDARD
    opts%standardize=.false.
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'character(kind=4,len=8) :: v'//nl//'character(len=8,kind=4) :: w'//nl// &
        'end program p',result,opts)
    if(.not.result%success()) error stop 'frontend regression: explicit character kind rejected'
    found=0
    do i=1,result%arena%entry_count
        d=query_declaration(result%arena,i)
        if(.not.d%found) cycle
        q=query_resolved_type(result%arena,i)
        if(.not.q%found .or. q%kind_value/=4) error stop 'frontend regression: explicit character kind lost'
        found=found+1
    end do
    if(found/=2) error stop 'frontend regression: missing explicit-kind declarations'
    ! Deliberately inconsistent guarded IR: even when upstream accepts the
    ! malformed expression, the adapter cannot admit its incomplete tree.
    p%name='p';p%ns=1;p%ne=1;p%nc=1
    allocate(p%symbols(1),p%expressions(1),p%code(1))
    p%symbols(1)%name='x';p%symbols(1)%typ=ty_integer
    p%expressions(1)%kind=ex_literal;p%expressions(1)%typ=ty_integer
    p%expressions(1)%value%tag=ty_integer; p%expressions(1)%value%i=1
    p%code(1)%op=op_assign;p%code(1)%line=4;p%code(1)%symbol=1;p%code(1)%a=1
    call verify_frontend('program p'//nl//'implicit none'//nl//'integer :: x'//nl// &
        'x=(1+)'//nl//'end program p',p,diag)
    if(diag%code==0) error stop 'adapter regression: incomplete binary tree admitted'
    diag=diagnostic_t()
    call verify_frontend('program p'//nl//'implicit none'//nl//'integer :: x'//nl// &
        'x=2'//nl//'end program p',p,diag)
    if(diag%code==0) error stop 'adapter regression: AST/IR literal mismatch admitted'
    diag=diagnostic_t()
    call verify_frontend('program p'//nl//'implicit none'//nl//'integer :: x'//nl// &
        'x=1'//nl//'end program p',p,diag)
    if(diag%code/=0) then
        print *,diag%message
        error stop 'adapter regression: matching AST/IR rejected'
    end if
    call parse_subset('program p'//nl//'implicit none'//nl//'integer :: i,j,s,stride'//nl// &
        's=0; stride=1'//nl//'do i=1,2,stride'//nl//'do j=1,2'//nl// &
        's=s+i+j'//nl//'end do'//nl//'end do'//nl//'print *,s'//nl//'end program p',p,diag)
    if(diag%code/=0) error stop 'adapter regression: nested-loop subset parse failed'
    call verify_frontend('program p'//nl//'implicit none'//nl//'integer :: i,j,s,stride'//nl// &
        's=0; stride=1'//nl//'do i=1,2,stride'//nl//'do j=1,2'//nl// &
        's=s+i+j'//nl//'end do'//nl//'end do'//nl//'print *,s'//nl//'end program p',p,diag)
    if(diag%code/=0) then
        print *,diag%message
        error stop 'adapter regression: explicit-scope loop binding failed'
    end if
    print '(a)', 'PASS: 7 mixed-mode + 1 explicit-kind compilations; 4 adapter contracts'
end program
