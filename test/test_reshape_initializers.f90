! SPDX-License-Identifier: MIT
program test_reshape_initializers
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant_shape, execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    integer(int64)::dims(3)
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,changed,attr
    integer::mode,e,shape,j,checks
    checks=0
    do mode=1,2
        attr=''
        if(mode==2) attr=',parameter'
        source='program p'//nl//'integer'//attr//'::a(2,3)=reshape([1,2,3,4,5,6],[2,3])'//nl// &
            'if(sum(a)/=21) error stop 1'//nl//'end program'
        call fixture()
        call verify_frontend(source,p,d)
        call expect(d%code==0,'valid adapter')
        call execute_program(p,d)
        call expect(d%code==0,'valid runtime')
        call evaluate_constant_shape(p,e,dims,d)
        call expect(d%code==0.and.all(dims==[2_int64,3_int64,1_int64]),'bounded dimensions')
        call expect(p%expressions(e)%extent==-1_int64.and.all(p%expressions(e)%dims==-1_int64), &
            'conservative metadata retained')
        ! Source and IR agree, and the flattened result has the right total
        ! size. The independent adapter must nevertheless reject swapped axes.
        changed='program p'//nl//'integer'//attr//'::a(2,3)=reshape([1,2,3,4,5,6],[3,2])'//nl// &
            'if(sum(a)/=21) error stop 1'//nl//'end program'
        p%expressions(p%expressions(shape)%args(1))%value%i=3
        p%expressions(p%expressions(shape)%args(2))%value%i=2
        call verify_frontend(changed,p,d)
        call expect(d%code/=0,'independent per-axis conformance')
        call parse_subset(changed,p,d)
        call expect(d%code/=0,'parser per-axis conformance')
        call fixture()
        p%expressions(e)%dims=[2_int64,3_int64,1_int64]
        call evaluate_constant_shape(p,e,dims,d)
        call expect(d%code/=0,'forged cached dimensions rejected')
        call fixture()
        p%expressions(shape)%args(1)=e
        call evaluate_constant_shape(p,e,dims,d)
        call expect(d%code/=0,'cyclic shape rejected')
        call fixture()
        call evaluate_constant_shape(p,0,dims,d)
        call expect(d%code/=0,'invalid root rejected')
    end do
    print *, 'PASS: RESHAPE initializer checks:',checks
contains
    subroutine fixture()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'RESHAPE initializer fixture'
        end if
        e=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op=='reshape') e=j
        end do
        if(e==0) error stop 'RESHAPE initializer missing'
        shape=p%expressions(e)%args(2)
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: RESHAPE initializer ',label,' mode=',mode
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
