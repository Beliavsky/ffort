! SPDX-License-Identifier: MIT
program test_matrix_norm_intrinsics
    use, intrinsic::iso_fortran_env,only:int64,real32,real64
    use, intrinsic::ieee_arithmetic,only:ieee_value,ieee_quiet_nan,ieee_positive_inf,ieee_is_negative
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,name,decl,shape,expr,body,kindtext
    integer::family,rk,form,mutation,e,a,b,k,j,checks,root,ma,s,n
    checks=0
    do family=1,3
      name='norm2';if(family==1)name='transpose'
      do rk=4,8,4
        kindtext='4';if(rk==8)kindtext='8'
        do form=1,3
          shape='(2,3)';if(family==3)shape='(2,3,2)'
          if(form==3)then
            shape='(0,3)';if(family==3)shape='(2,3,0)'
          end if
          decl='real('//kindtext//')::x'//shape//nl
          expr=name//'(x)';if(family==3)expr=name//'(x,2)'
          if(family==1)decl=decl//'real('//kindtext//')::y(3,2)'//nl
          if(family==2)decl=decl//'real('//kindtext//')::y'//nl
          if(family==3)decl=decl//'real('//kindtext//')::y(2,2)'//nl
          if(form==3)then
            decl='real('//kindtext//')::x'//shape//nl
            if(family==1)decl=decl//'real('//kindtext//')::y(3,0)'//nl
            if(family==2)decl=decl//'real('//kindtext//')::y'//nl
            if(family==3)decl=decl//'real('//kindtext//')::y(2,0)'//nl
          end if
          body='x=1'//nl//'y='//expr
          if(form==2)then
            decl=decl//'integer::z'//nl
            body='z=kind('//expr//')'
          end if
          source='program p'//nl//'implicit none'//nl//decl//body//nl//'end program'
          ma=33;if(family==3)ma=40
          do mutation=0,ma
            call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
            e=0
            do j=1,p%ne
              if(p%expressions(j)%op==name)e=j
            end do
            call expect(e>0,'intrinsic occurrence')
            a=p%expressions(e)%args(1);s=p%expressions(a)%symbol
            if(family==3)b=p%expressions(e)%args(2)
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_logical
            case(2);p%expressions(e)%real_kind=16
            case(3);p%expressions(e)%real_kind=12-rk
            case(4);p%expressions(e)%rank=4
            case(5);p%expressions(e)%extent=77
            case(6);p%expressions(e)%dims=[1_int64,2_int64,3_int64]
            case(7);p%expressions(e)%intrinsic_mask=1
            case(8);p%expressions(e)%args=[integer::]
            case(9);p%expressions(e)%args=[p%expressions(e)%args,a,a]
            case(10);deallocate(p%expressions(e)%args)
            case(11);p%expressions(e)%args(1)=0
            case(12);p%expressions(e)%args(1)=p%ne+1
            case(13);p%expressions(e)%args(1)=e
            case(14);p%expressions(a)%typ=ty_integer
            case(15);p%expressions(a)%real_kind=16
            case(16);p%expressions(a)%rank=4
            case(17);p%symbols(s)%real_kind=12-rk
            case(18);p%expressions(a)%extent=99
            case(19);p%expressions(a)%dims=[9_int64,9_int64,9_int64]
            case(20);p%expressions(e)%symbol=1
            case(21);p%expressions(e)%left=a
            case(22);p%expressions(e)%length_expr=a
            case(23);p%expressions(e)%character_len=3
            case(24);p%expressions(e)%constructor_kind_expr=a
            case(25);p%expressions(e)%scope=99
            case(26);p%expressions(a)%scope=99
            case(27);p%expressions(a)%args=[a]
            case(28);p%expressions(a)%op='bogus'
            case(29);p%expressions(a)%left=a
            case(30);p%expressions(a)%triplet(2)=.true.
            case(31);p%expressions(e)%bound_type=1
            case(32);p%expressions(e)%triplet(2)=.true.
            case(33);p%expressions(a)%character_len=7
            case(34);p%expressions(b)%typ=ty_real
            case(35);p%expressions(b)%real_kind=16
            case(36);p%expressions(b)%rank=1
            case(37);p%expressions(b)%extent=1
            case(38);p%expressions(b)%dims=1
            case(39);p%expressions(b)%value%tag=ty_real
            case(40);p%expressions(b)%value%real_kind=8
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter guard')
            d=diagnostic_t();call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime guard')
            ! KIND has no active frame, so scope-only corruption is tested by
            ! ordinary execution above rather than the constant evaluator.
            if(mutation==25.or.mutation==26)cycle
            k=p%ne+1;p%ne=k
            p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t();call evaluate_constant(p,k,v,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND guard')
            if(mutation==0)call expect(v%i==rk,'result kind')
          end do
        end do
      end do
    end do
    ! Same-rank indirect cycle below the transformation's operand.
    do family=1,2
      name='norm2';if(family==1)name='transpose'
      source='program p'//nl//'real::x(2,3)'//nl//'print *,'//name//'(x)'//nl//'end program'
      call parse_subset(source,p,d);call expect(d%code==0,'cycle fixture')
      e=p%code(1)%items(1);a=p%expressions(e)%args(1)
      p%expressions(a)%kind=ex_unary;p%expressions(a)%symbol=0;p%expressions(a)%op='+'
      p%expressions(a)%left=a
      call execute_program(p,d);call expect(d%code/=0,'indirect cycle rejected')
    end do
    ! Direct IR data can contain IEEE values which source syntax does not.
    do j=1,3
      source='program p'//nl//'print *,norm2([0.0])'//nl//'end program'
      call parse_subset(source,p,d);call expect(d%code==0,'nonfinite fixture')
      e=p%code(1)%items(1);a=p%expressions(e)%args(1);a=p%expressions(a)%args(1)
      if(j==1)p%expressions(a)%value%r=ieee_value(0d0,ieee_quiet_nan)
      if(j==2)p%expressions(a)%value%r=ieee_value(0d0,ieee_positive_inf)
      if(j==3)p%expressions(a)%value%r=huge(0d0)
      call execute_program(p,d);call expect(d%code/=0,'invalid evaluated value rejected')
      k=p%ne+1;p%ne=k
      p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
      d=diagnostic_t();call evaluate_constant(p,k,v,d)
      call expect(d%code==0.and.v%i==4,'KIND ignores runtime data')
    end do
    call parse_subset('program p'//nl//'print *,norm2([-0.0,0.0])'//nl//'end program',p,d)
    call expect(d%code==0,'zero fixture')
    e=p%code(1)%items(1);call evaluate_constant(p,e,v,d)
    call expect(d%code==0.and.v%r==0d0.and..not.ieee_is_negative(v%r),'positive zero norm')
    print *,'PASS: matrix/norm independent assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,name,rk,form,mutation,label
      if(allocated(d%message))print *,d%message
      error stop 'matrix/norm invariant failure'
    end subroutine
end program
