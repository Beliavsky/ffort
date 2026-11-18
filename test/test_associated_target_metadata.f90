! SPDX-License-Identifier: MIT
program test_associated_target_metadata
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,decl,expr,name,output
    integer::t,rk,form,m,e,a,b,j,k,checks,context
    checks=0
    do t=ty_integer,ty_real
      do rk=4,8,4
        decl='integer';if(t==ty_real)decl='real'
        if(rk==8)decl=decl//'(8)'
        do context=1,2
        do form=1,3
          expr='a';if(form==2)expr='a(1:4:2)'
          if(form==3)expr='q'
          output='associated(p,'//expr//')'
          if(context==2)output='z.and.'//output
          source='program main'//nl//'implicit none'//nl//decl//',target::a(4)'//nl// &
            decl//',pointer::p(:),q(:)'//nl//'logical::z(0)'//nl//'p=>a'//nl//'q=>p'//nl// &
            'print *,'//output//nl//'end program'
          do m=0,42
            d=diagnostic_t();call parse_subset(source,p,d);call expect(d%code==0,'honest parse')
            e=0
            do j=1,p%ne
              if(p%expressions(j)%op=='associated')e=j
            end do
            call expect(e>0,'call found')
            a=p%expressions(e)%args(1);b=p%expressions(e)%args(2)
            select case(m)
            case(1);p%expressions(e)%typ=ty_integer
            case(2);p%expressions(e)%real_kind=8
            case(3);p%expressions(e)%rank=1
            case(4);p%expressions(e)%extent=1
            case(5);p%expressions(e)%dims=[1,0,0]
            case(6);p%expressions(e)%intrinsic_mask=1
            case(7);p%expressions(e)%symbol=1
            case(8);p%expressions(e)%left3=1
            case(9);p%expressions(e)%args=[integer::]
            case(10);p%expressions(e)%args=[a,b,b]
            case(11);deallocate(p%expressions(e)%args)
            case(12);p%expressions(e)%args(1)=0
            case(13);p%expressions(e)%args(2)=p%ne+1
            case(14);p%expressions(e)%args(2)=e
            case(15);p%expressions(b)%parenthesized=.true.
            case(16);p%expressions(b)%kind=ex_binary
            case(17);p%expressions(b)%symbol=0
            case(18);p%expressions(b)%scope=999
            case(19);p%expressions(b)%typ=ty_logical
            case(20);p%expressions(b)%real_kind=12-rk
            case(21);p%expressions(b)%rank=0
            case(22);p%expressions(b)%dims=[1,0,0]
            case(23);p%expressions(b)%extent=p%expressions(b)%extent+7
            case(24);p%expressions(b)%third=1
            case(25);p%expressions(b)%left3=1
            case(26);p%expressions(b)%args=[a]
            case(27);p%expressions(b)%character_len=0
            case(28);p%expressions(b)%generic_id=1
            case(29);p%expressions(b)%bound_type=1
            case(30);p%expressions(a)%third=1
            case(31);p%expressions(a)%rank=0
            case(32);p%expressions(a)%triplet(2)=.true.
            case(33);p%expressions(b)%intrinsic_mask=1
            case(34);p%expressions(a)%symbol=1
            case(35);p%expressions(e)%scope=999
            case(36);p%expressions(a)%scope=999
            case(37);p%expressions(e)%bound_binding=1
            case(38);p%expressions(b)%bound_binding=1
            case(39);p%expressions(b)%op='+'
            case(40);p%expressions(a)%op='+'
            case(41);p%expressions(e)%triplet(2)=.true.
            case(42);p%expressions(e)%triplet(1)=.false.
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(m==0),'adapter guard')
            d=diagnostic_t();call execute_program(p,d)
            call expect((d%code==0).eqv.(m==0),'direct runtime guard')
            k=p%ne+1;p%ne=k
            p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t();call evaluate_constant(p,k,v,d)
            call expect((d%code==0).eqv.(m==0),'KIND structural guard')
            if(m==0)call expect(v%i==4,'KIND scalar default LOGICAL')
          end do
        end do
        end do
      end do
    end do
    print *,'PASS: ASSOCIATED target metadata assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,'FAIL ',label,' type,kind,form,context,mutation:',t,rk,form,context,m
      if(allocated(d%message))print *,d%message
      error stop 1
    end subroutine
end program
