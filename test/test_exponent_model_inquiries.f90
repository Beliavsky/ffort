! SPDX-License-Identifier: MIT
program test_exponent_model_inquiries
    use, intrinsic :: iso_fortran_env, only: int64,real32,real64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(11),parameter::names(2)=[character(11)::'minexponent','maxexponent']
    character(:),allocatable::source,decl,expr,suffix
    integer::op,k,r,context,m,e,a,j,outer,checks,wanted
    checks=0
    do op=1,2
      do k=4,8,4
        wanted=merge(minexponent(0.0_real32),maxexponent(0.0_real32),op==1)
        if(k==8)wanted=merge(minexponent(0.0_real64),maxexponent(0.0_real64),op==1)
        do r=0,3
          suffix=''
          if(r==1)suffix='(0)'
          if(r==2)suffix='(2,0)'
          if(r==3)suffix='(2,0,3)'
          decl='real::x'//suffix
          if(k==8)decl='real(8)::x'//suffix
          do context=1,2
            expr=trim(names(op))//'(x=x)'
            if(context==2)expr='z+'//expr
            source='program main'//nl//'implicit none'//nl//decl//nl// &
              'integer::z(0)'//nl//'print *,'//expr//nl//'end program'
            do m=0,22
              call parse_subset(source,p,d);call expect(d%code==0,'parse')
              e=0
              do j=1,p%ne
                if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op==trim(names(op)))e=j
              end do
              call expect(e>0,'find call');a=p%expressions(e)%args(1)
              select case(m)
              case(1);p%expressions(e)%typ=ty_real
              case(2);p%expressions(e)%real_kind=8
              case(3);p%expressions(e)%rank=1
              case(4);p%expressions(e)%extent=1
              case(5);p%expressions(e)%dims=[1,0,0]
              case(6);p%expressions(e)%intrinsic_mask=1
              case(7);p%expressions(e)%args=[integer::]
              case(8);p%expressions(e)%args=[a,a]
              case(9);deallocate(p%expressions(e)%args)
              case(10);p%expressions(e)%args(1)=0
              case(11);p%expressions(e)%args(1)=p%ne+1
              case(12);p%expressions(e)%args(1)=e
              case(13);p%expressions(a)%typ=ty_integer
              case(14);p%expressions(a)%real_kind=12-k
              case(15);p%expressions(a)%rank=4
              case(16);p%expressions(a)%kind=ex_component
              case(17);p%expressions(a)%symbol=0
              case(18);p%expressions(a)%extent=max_array_elements+1
              case(19);p%expressions(a)%kind=ex_section
              case(20);p%expressions(a)%kind=ex_element
              case(21);p%expressions(a)%kind=ex_gather_rows
              case(22);p%expressions(e)%intrinsic_mask=-1
              end select
              call verify_frontend(source,p,d);call expect((d%code==0).eqv.(m==0),'adapter')
              d=diagnostic_t();call execute_program(p,d);call expect((d%code==0).eqv.(m==0),'direct runtime')
              outer=p%ne+1;p%ne=outer
              p%expressions(outer)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
              d=diagnostic_t();call evaluate_constant(p,outer,v,d);call expect((d%code==0).eqv.(m==0),'KIND structure')
              if(m==0)then
                call expect(v%i==4,'default INTEGER kind')
                call evaluate_constant(p,e,v,d);call expect(d%code==0.and.v%i==wanted,'model exponent')
              end if
            end do
          end do
        end do
      end do
    end do
    do op=1,2
      source='program main'//nl//'print *,'//trim(names(op))//'(1.0)'//nl//'end program'
      call parse_subset(source,p,d);call expect(d%code==0,'DAG parse')
      e=0
      do j=1,p%ne
        if(p%expressions(j)%op==trim(names(op)))e=j
      end do
      call expect(e>0,'DAG call');a=p%expressions(e)%args(1)
      do j=1,48
        p%ne=p%ne+1
        p%expressions(p%ne)=expr_t(kind=ex_binary,typ=ty_real,op='+',left=a,right=a)
        a=p%ne
      end do
      p%expressions(e)%args=[a]
      call evaluate_constant(p,e,v,d);call expect(d%code==0,'memoized shared DAG')
      p%expressions(a)%left=a
      d=diagnostic_t();call evaluate_constant(p,e,v,d);call expect(d%code/=0,'cycle rejects')
      outer=p%ne+1;p%ne=outer
      p%expressions(outer)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
      d=diagnostic_t();call evaluate_constant(p,outer,v,d);call expect(d%code/=0,'KIND cycle rejects')
    end do
    print *,'PASS: exponent-model adapter/runtime/KIND assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,'FAIL ',label,' op/kind/rank/context/mutation:',op,k,r,context,m
      if(allocated(d%message))print *,d%message
      error stop 1
    end subroutine
end program
