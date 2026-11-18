! SPDX-License-Identifier: MIT
program test_array_bounds_inquiry
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant,evaluate_constant_array
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    type(value_t),allocatable::values(:)
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,name,decl,sh,expr,body,ks
    integer::family,rk,r,form,mutation,e,a,b,j,k,s,checks,maxmut
    checks=0
    do family=1,2
      name='lbound';if(family==2)name='ubound'
      do rk=4,8,4
        ks='4';if(rk==8)ks='8'
        do r=1,3
          sh='(-2:0)'
          if(r==2)sh='(-2:0,5:6)'
          if(r==3)sh='(-2:0,5:6,-4:-3)'
          do form=1,3
            decl='real::x'//sh//nl//'integer('//ks//')::y'
            expr=name//'(x,kind='//ks//')'
            if(form/=3)then
              if(r==1)decl=decl//'(1)'
              if(r==2)decl=decl//'(2)'
              if(r==3)decl=decl//'(3)'
            else
              expr=name//'(x,1,kind='//ks//')'
            end if
            body='y='//expr
            if(form==2)body='y=kind('//expr//')'
            source='program p'//nl//'implicit none'//nl//decl//nl//body//nl//'end program'
            maxmut=44;if(form==3)maxmut=51
            do mutation=0,maxmut
              call parse_subset(source,p,d);call expect(d%code==0,'parse control')
              e=0
              do j=1,p%ne
                if(p%expressions(j)%op==name)e=j
              end do
              call expect(e>0,'find inquiry')
              a=p%expressions(e)%args(1);s=p%expressions(a)%symbol
              b=p%expressions(e)%args(size(p%expressions(e)%args))
              select case(mutation)
              case(1);p%expressions(e)%typ=ty_real
              case(2);p%expressions(e)%real_kind=16
              case(3);p%expressions(e)%real_kind=12-rk
              case(4);p%expressions(e)%rank=4
              case(5);p%expressions(e)%extent=77
              case(6);p%expressions(e)%dims=1
              case(7);p%expressions(e)%intrinsic_mask=0
              case(8);p%expressions(e)%intrinsic_mask=2
              case(9);p%expressions(e)%args=[integer::]
              case(10);deallocate(p%expressions(e)%args)
              case(11);p%expressions(e)%args(1)=0
              case(12);p%expressions(e)%args(1)=p%ne+1
              case(13);p%expressions(e)%args(1)=e
              case(14);p%expressions(a)%typ=ty_integer
              case(15);p%expressions(a)%real_kind=16
              case(16);p%expressions(a)%rank=4
              case(17);p%symbols(s)%real_kind=8
              case(18);p%expressions(a)%extent=99
              case(19);p%expressions(a)%dims=9
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
              case(41);p%expressions(b)%value%i=3
              case(42);p%expressions(e)%intrinsic_mask=8
              case(43);p%expressions(e)%generic_id=1
              case(44);p%expressions(e)%right3=a
              case(45);p%expressions(p%expressions(e)%args(2))%typ=ty_real
              case(46);p%expressions(p%expressions(e)%args(2))%real_kind=16
              case(47);p%expressions(p%expressions(e)%args(2))%rank=1
              case(48);p%expressions(p%expressions(e)%args(2))%extent=1
              case(49);p%expressions(p%expressions(e)%args(2))%dims=1
              case(50);p%expressions(p%expressions(e)%args(2))%value%tag=ty_real
              case(51);p%expressions(p%expressions(e)%args(2))%value%real_kind=8
              end select
              call verify_frontend(source,p,d)
              call expect((d%code==0).eqv.(mutation==0),'independent adapter guard')
              d=diagnostic_t();call execute_program(p,d)
              call expect((d%code==0).eqv.(mutation==0),'runtime guard')
              if(mutation==25.or.mutation==26)cycle
              k=p%ne+1;p%ne=k
              p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
              d=diagnostic_t();call evaluate_constant(p,k,v,d)
              call expect((d%code==0).eqv.(mutation==0),'public KIND guard')
              if(mutation==0)call expect(v%i==rk,'KIND result')
            end do
          end do
        end do
      end do
    end do
    ! An empty surrounding array must still validate every inquiry descriptor.
    do family=1,2
      name='lbound';if(family==2)name='ubound'
      source='program p'//nl//'real::x(2,3)'//nl//'integer::a(0),b(0)'//nl// &
             'b=a+sum('//name//'(x,kind=8))'//nl//'end program'
      do mutation=0,12
        call parse_subset(source,p,d);call expect(d%code==0,'empty surrounding parse')
        do j=1,p%ne
          if(p%expressions(j)%op==name)e=j
        end do
        a=p%expressions(e)%args(1);b=p%expressions(e)%args(2)
        select case(mutation)
        case(1);p%expressions(e)%rank=0
        case(2);p%expressions(e)%real_kind=4
        case(3);p%expressions(e)%extent=99
        case(4);p%expressions(e)%intrinsic_mask=3
        case(5);p%expressions(e)%args(1)=e
        case(6);p%expressions(a)%extent=99
        case(7);p%expressions(a)%dims=99
        case(8);p%expressions(a)%scope=99
        case(9);p%expressions(b)%value%i=3
        case(10);p%expressions(b)%typ=ty_real
        case(11);p%expressions(e)%left=a
        case(12);p%expressions(a)%symbol=0
        end select
        call execute_program(p,d)
        call expect((d%code==0).eqv.(mutation==0),'empty surrounding metadata guard')
      end do
    end do
    ! Public array evaluation of declared, undefined ARRAY does not fetch data.
    do family=1,2
      name='lbound';if(family==2)name='ubound'
      source='program p'//nl//'real::x(-2:0,5:6,4:3)'//nl//'print *,'//name//'(x,kind=8)'//nl//'end program'
      call parse_subset(source,p,d);call expect(d%code==0,'public constant inquiry parse')
      e=p%code(1)%items(1)
      call evaluate_constant_array(p,e,values,d);call expect(d%code==0,'public constant inquiry run')
      call expect(size(values)==3,'public vector extent')
      if(family==1)call expect(all(values%i==[-2_int64,5_int64,1_int64]),'empty axis lower bounds')
      if(family==2)call expect(all(values%i==[0_int64,6_int64,0_int64]),'empty axis upper bounds')
      call expect(all(values%real_kind==8),'public vector KIND')
    end do
    ! Indirect DAG cycle must terminate before shape preparation, even in KIND.
    source='program p'//nl//'real::x(2)'//nl//'integer::k'//nl//'k=kind(lbound(x))'//nl//'end program'
    call parse_subset(source,p,d);call expect(d%code==0,'cycle parse')
    do j=1,p%ne
      if(p%expressions(j)%op=='lbound')e=j
    end do
    a=p%expressions(e)%args(1)
    p%expressions(a)%kind=ex_unary;p%expressions(a)%symbol=0;p%expressions(a)%op='+'
    p%expressions(a)%left=a
    call execute_program(p,d);call expect(d%code/=0,'indirect cycle rejects')
    print *,'PASS: array bounds inquiry assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,name,rk,r,form,mutation,label
      if(allocated(d%message))print *,d%message
      error stop 'array bounds inquiry guard failure'
    end subroutine
end program
