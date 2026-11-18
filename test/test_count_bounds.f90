! SPDX-License-Identifier: MIT
program test_count_bounds
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p,q
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'function f(mask) result(a)'//nl//'logical,intent(in)::mask(:)'//nl// &
        'integer::a(count(mask))'//nl//'a=3'//nl//'end function'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'implicit none'//nl// &
        'if(sum(f([.true.,.false.,.true.]))/=6) error stop 1'//nl//'end program'
    integer::j,s,mask,root,mask_expr,mode,checks
    checks=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'parse')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'adapter')
    call execute_program(p,d)
    call expect(d%code==0,'runtime')
    s=p%procedures(1)%result_symbol
    mask=p%procedures(1)%args(1)
    root=p%symbols(s)%upper_expr
    mask_expr=p%expressions(root)%args(1)
    call expect(valid_automatic_bound(p,root,1),'valid count grammar')
    do mode=1,12
        q=p;d=diagnostic_t()
        select case(mode)
        case(1);q%expressions(root)%args(1)=q%ne+1
        case(2);q%expressions(root)%args(1)=0
        case(3);q%expressions(root)%intrinsic_mask=0
        case(4);q%expressions(root)%intrinsic_mask=7
        case(5);q%symbols(mask)%dummy_intent=2
        case(6);q%symbols(mask)%is_optional=.true.
        case(7);q%expressions(mask_expr)%typ=ty_integer
        case(8);q%expressions(mask_expr)%rank=0
        case(9);q%expressions(root)%args=[integer::]
        case(10);q%expressions(root)%op='sum'
        case(11)
            q%expressions(mask_expr)%kind=ex_unary
            q%expressions(mask_expr)%op='.not.'
            q%expressions(mask_expr)%left=mask_expr
        case(12);q%symbols(mask)%is_dummy=.false.
        end select
        call expect(.not.valid_automatic_bound(q,root,1),'reject malformed count grammar')
        call verify_frontend(source,q,d)
        call expect(d%code/=0,'adapter rejects count corruption')
        d=diagnostic_t()
        call execute_program(q,d)
        call expect(d%code==2,'runtime rejects count corruption')
    end do
    d=diagnostic_t()
    call execute_program(p,d,max_steps=12_int64)
    call expect(d%code==2,'shared count budget')
    print *, 'PASS: COUNT bounds and malformed IR checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' mutation=',mode
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
