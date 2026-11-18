! SPDX-License-Identifier: MIT
program test_newline_intrinsic
    use, intrinsic :: iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,decl,arg,expr
    integer::form,context,m,j,e,a,outer,checks,mutations
    checks=0
    do form=1,5
      decl='';arg="'a'"
      if(form==2)then
        decl='character(7)::a';arg='a'
      else if(form==3)then
        decl='character(0)::a(0,2,3)';arg='a'
      else if(form==4)then
        decl='character(:),allocatable::a(:,:,:)';arg='a'
      else if(form==5)then
        arg="new_line(a='a')"
      end if
      do context=1,2
        expr='new_line(a='//arg//')'
        if(context==2)expr="z//"//expr
        source='program p'//nl//'implicit none'//nl//decl//nl//'character::z(0)'//nl//'print *,'//expr//nl//'end program'
        mutations=20
        if(form==1.or.form==5)mutations=23
        do m=0,mutations
          call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
          e=0
          do j=1,p%ne
            if(p%expressions(j)%op=='new_line')e=j
          end do
          call expect(e>0,'find call');a=p%expressions(e)%args(1)
          select case(m)
          case(1);p%expressions(e)%typ=ty_real
          case(2);p%expressions(e)%real_kind=8
          case(3);p%expressions(e)%rank=1
          case(4);p%expressions(e)%extent=1
          case(5);p%expressions(e)%dims=[1_int64,0_int64,0_int64]
          case(6);p%expressions(e)%intrinsic_mask=1
          case(7);p%expressions(e)%args=[integer::]
          case(8);p%expressions(e)%args=[a,a]
          case(9);deallocate(p%expressions(e)%args)
          case(10);p%expressions(e)%args(1)=0
          case(11);p%expressions(e)%args(1)=p%ne+1
          case(12);p%expressions(e)%args(1)=e
          case(13);p%expressions(a)%typ=ty_integer
          case(14);p%expressions(a)%real_kind=8
          case(15);p%expressions(a)%rank=4
          case(16);p%expressions(a)%kind=ex_component
          case(17);p%expressions(e)%character_len=0
          case(18);p%expressions(a)%character_len=65537
          case(19);p%expressions(a)%kind=ex_section
          case(20);p%expressions(e)%intrinsic_mask=-1
          case(21:23)
            j=a
            if(form==5)j=p%expressions(j)%args(1)
            if(m==21)p%expressions(j)%value%real_kind=8
            if(m==22)p%expressions(j)%value%s='aa'
            if(m==23)deallocate(p%expressions(j)%value%s)
          end select
          call verify_frontend(source,p,d);call expect((d%code==0).eqv.(m==0),'adapter')
          d=diagnostic_t();call execute_program(p,d);call expect((d%code==0).eqv.(m==0),'direct runtime')
          outer=p%ne+1;p%ne=outer
          p%expressions(outer)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
          d=diagnostic_t();call evaluate_constant(p,outer,v,d);call expect((d%code==0).eqv.(m==0),'KIND structure')
          if(m==0)then
            call expect(v%i==1,'Fortran default CHARACTER kind')
            call evaluate_constant(p,e,v,d);call expect(d%code==0,'value')
            call expect(v%tag==ty_character.and.v%real_kind==4.and.v%s==nl,'newline value')
          end if
        end do
      end do
    end do
    ! Shared DAG remains linear; indirect cycles reject before any data access.
    call parse_subset('program p'//nl//"print *,new_line('a')"//nl//'end program',p,d)
    call expect(d%code==0,'DAG parse');e=p%code(1)%items(1);a=p%expressions(e)%args(1)
    do j=1,48
      p%ne=p%ne+1
      p%expressions(p%ne)=expr_t(kind=ex_binary,typ=ty_character,op='//',left=a,right=a,character_len=-1)
      a=p%ne
    end do
    p%expressions(e)%args=[a]
    call evaluate_constant(p,e,v,d);call expect(d%code==0,'memoized shared DAG')
    p%expressions(a)%left=a
    d=diagnostic_t();call evaluate_constant(p,e,v,d);call expect(d%code/=0,'indirect cycle')
    print *,'PASS: NEW_LINE adapter/runtime/KIND assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,'FAIL ',label,' form/context/mutation:',form,context,m
      if(allocated(d%message))print *,d%message
      error stop 1
    end subroutine
end program
