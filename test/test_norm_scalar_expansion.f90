! SPDX-License-Identifier: MIT
program test_norm_scalar_expansion
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant_array
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t),allocatable::values(:)
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,expr,suffix,name
    integer::checks,k,order,form,index,j,a,mutation
    checks=0
    ! Public constant-array evaluation supplies positions 1 through 4 to the
    ! enclosing expression. The scalar norm must broadcast at every position.
    do k=4,8,4
      suffix='';if(k==8)suffix='_8'
      do order=1,2
        do form=1,2
          expr='norm2([3.0'//suffix//',4.0'//suffix//'])'
          if(form==2)expr='norm2([3.0'//suffix//',4.0'//suffix//'],1_8)'
          if(order==1)then
            expr='[1.0'//suffix//',2.0'//suffix//',3.0'//suffix//',4.0'//suffix//']+'//expr
          else
            expr=expr//'+[1.0'//suffix//',2.0'//suffix//',3.0'//suffix//',4.0'//suffix//']'
          end if
          source='program p'//nl//'print *,'//expr//nl//'end program'
          call parse_subset(source,p,d);call expect(d%code==0,'parse scalar position fixture')
          index=p%code(1)%items(1)
          call evaluate_constant_array(p,index,values,d)
          call expect(d%code==0,'public array evaluation')
          call expect(size(values)==4,'result extent')
          do j=1,4
            call expect(values(j)%tag==ty_real.and.values(j)%real_kind==k,'result type/kind')
            call expect(values(j)%r==real(j+5,kind(0d0)),'distinct enclosing position broadcasts scalar')
          end do
        end do
      end do
    end do
    ! A genuinely array-valued operation may not be forged into a scalar to
    ! bypass its shape or true array position validation.
    do form=1,2
      name='transpose';expr='transpose(x)'
      source='real::x(2,3),y(3,2)'
      if(form==2)then
        name='norm2';expr='norm2(x,1)';source='real::x(2,3),y(3)'
      end if
      source='program p'//nl//source//nl//'x=1'//nl//'y='//expr//nl//'end program'
      do mutation=0,5
        call parse_subset(source,p,d);call expect(d%code==0,'parse true array fixture')
        index=0
        do j=1,p%ne
          if(p%expressions(j)%op==name)index=j
        end do
        call expect(index>0,'true array operation found')
        select case(mutation)
        case(1)
          p%expressions(index)%rank=0;p%expressions(index)%extent=0;p%expressions(index)%dims=0
        case(2);p%expressions(index)%extent=0
        case(3);p%expressions(index)%extent=99
        case(4);p%expressions(index)%dims=99
        case(5);p%expressions(index)%rank=3
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'adapter true array guard')
        d=diagnostic_t();call execute_program(p,d)
        call expect((d%code==0).eqv.(mutation==0),'runtime true array guard')
      end do
    end do
    ! Actual out-of-range element accesses after a valid transformation still
    ! reject. Mutate the dynamic index in IR without changing the source text.
    source='program p'//nl//'real::x(2,3),v(3)'//nl//'integer::i'//nl// &
           'x=1'//nl//'v=norm2(x,1)'//nl//'i=3'//nl//'print *,v(i)'//nl//'end program'
    call parse_subset(source,p,d);call expect(d%code==0,'index fixture parse')
    index=0
    do j=1,p%ne
      if(p%expressions(j)%kind==ex_literal.and.p%expressions(j)%typ==ty_integer)then
        if(p%expressions(j)%value%i==3)index=j
      end if
    end do
    call expect(index>0,'index literal found')
    p%expressions(index)%value%i=4
    call execute_program(p,d);call expect(d%code==2,'invalid true array index rejected')
    print *,'PASS: NORM2 scalar expansion native assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,label,k,order,form,mutation
      if(allocated(d%message))print *,d%message
      error stop 'NORM2 scalar expansion invariant failure'
    end subroutine
end program
