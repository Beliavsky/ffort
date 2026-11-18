! SPDX-License-Identifier: MIT
program test_integer_kinds_runtime
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_runtime, only: evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    integer(int64),parameter::hi=huge(0_int64),lo=-hi-1_int64
    call arithmetic('+',9007199254740993_int64,2_int64,8,9007199254740995_int64,.true.)
    call arithmetic('+',hi,1_int64,8,0_int64,.false.)
    call arithmetic('-',lo,1_int64,8,0_int64,.false.)
    call arithmetic('*',lo,-1_int64,8,0_int64,.false.)
    call arithmetic('/',lo,-1_int64,8,0_int64,.false.)
    call arithmetic('**',2_int64,63_int64,8,0_int64,.false.)
    call arithmetic('+',2147483647_int64,1_int64,4,0_int64,.false.)
    call arithmetic('*',-3037000499_int64,-3037000499_int64,8,9223372030926249001_int64,.true.)
    print '(a)','PASS: direct INTEGER kind runtime exactness and checked arithmetic'
contains
    subroutine arithmetic(op,a,b,rk,expected,valid)
        character(*),intent(in)::op
        integer(int64),intent(in)::a,b,expected
        integer,intent(in)::rk
        logical,intent(in)::valid
        p=program_t();d=diagnostic_t()
        allocate(p%symbols(0),p%expressions(3),p%code(0))
        p%ne=3
        p%expressions(1)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=rk, &
            value=value_t(tag=ty_integer,real_kind=rk,i=a))
        p%expressions(2)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=rk, &
            value=value_t(tag=ty_integer,real_kind=rk,i=b))
        p%expressions(3)=expr_t(kind=ex_binary,typ=ty_integer,real_kind=rk,left=1,right=2,op=op)
        call evaluate_constant(p,3,v,d)
        if((d%code==0).neqv.valid) error stop 'integer runtime diagnostic mismatch'
        if(valid) then
            if(v%i/=expected.or.v%real_kind/=rk) error stop 'integer runtime value mismatch'
        end if
    end subroutine
end program
