! SPDX-License-Identifier: MIT
program test_real_round_inverse
    use, intrinsic::iso_fortran_env,only:int64,real32,real64
    use, intrinsic::ieee_arithmetic,only:ieee_value,ieee_quiet_nan,ieee_positive_inf
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(5),parameter::names(4)=[character(5)::'aint','anint','asinh','acosh']
    character(:),allocatable::source,name,expr,call_text,decl,arg,suffix
    integer::family,rk,form,mutation,e,a,k,j,checks,nmut,outkind
    checks=0
    do family=1,4
      name=trim(names(family))
      do rk=4,8,4
        suffix='';if(rk==8)suffix='d0'
        arg='2.5';if(family<=2)arg='-2.5'
        arg=arg//suffix
        decl='real';if(rk==8)decl='real(8)'
        do form=1,4
          if(form==4.and.family>2)cycle
          call_text=name//'('//arg//')';outkind=rk
          if(form==3)call_text=name//'(z)'
          if(form==4)then
            if(rk==4)call_text=name//'('//arg//',8)'
            if(rk==8)call_text=name//'('//arg//',4)'
            outkind=12-rk
          end if
          expr=call_text;if(form==2)expr='kind('//call_text//')'
          source='program p'//nl//'implicit none'//nl
          if(form==3)source=source//decl//'::z(0,2,3)'//nl
          source=source//'print *,'//expr//nl//'end program'
          nmut=19;if(form==4)nmut=26
          do mutation=0,nmut
            call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
            e=0
            do j=1,p%ne
              if(p%expressions(j)%op==name)e=j
            end do
            call expect(e>0,'intrinsic occurrence')
            a=p%expressions(e)%args(1)
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_integer
            case(2);p%expressions(e)%real_kind=16
            case(3);p%expressions(e)%rank=4
            case(4);p%expressions(e)%extent=77
            case(5);p%expressions(e)%dims=[1_int64,2_int64,3_int64]
            case(6);p%expressions(e)%intrinsic_mask=1
            case(7);p%expressions(e)%args=[integer::]
            case(8);p%expressions(e)%args=[p%expressions(e)%args,a]
            case(9);deallocate(p%expressions(e)%args)
            case(10);p%expressions(e)%args(1)=0
            case(11);p%expressions(e)%args(1)=p%ne+1
            case(12);p%expressions(e)%args(1)=e
            case(13);p%expressions(a)%typ=ty_integer
            case(14);p%expressions(a)%real_kind=16
            case(15);p%expressions(a)%rank=4
            case(16)
              if(form==3)then
                p%symbols(p%expressions(a)%symbol)%real_kind=12-rk
              else
                ! Unary minus may wrap the literal.
                k=a
                if(p%expressions(k)%kind==ex_unary)k=p%expressions(k)%left
                p%expressions(k)%value%real_kind=12-rk
              end if
            case(17);p%expressions(a)%extent=99
            case(18);p%expressions(a)%dims=[9_int64,9_int64,9_int64]
            case(19);p%expressions(e)%real_kind=12-outkind
            case(20);p%expressions(p%expressions(e)%args(2))%typ=ty_real
            case(21);p%expressions(p%expressions(e)%args(2))%value%i=16
            case(22);p%expressions(p%expressions(e)%args(2))%rank=1
            case(23);p%expressions(p%expressions(e)%args(2))%extent=1
            case(24);p%expressions(p%expressions(e)%args(2))%dims=[1_int64,0_int64,0_int64]
            case(25);p%expressions(p%expressions(e)%args(2))%value%real_kind=8
            case(26);p%expressions(p%expressions(e)%args(2))%kind=ex_user_call
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter guard')
            d=diagnostic_t();call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime guard')
            k=p%ne+1;p%ne=k
            p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t();call evaluate_constant(p,k,v,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND guard')
            if(mutation==0)call expect(v%i==outkind,'result kind')
          end do
        end do
      end do
    end do
    ! Indirect cycles share the structural walk's marks rather than restarting
    ! validation recursively with fresh marks.
    call parse_subset('program p'//nl//'print *,aint(1d0,4)'//nl//'end program',p,d)
    call expect(d%code==0,'cycle fixture parse')
    e=p%code(1)%items(1);k=p%ne+1;p%ne=k
    p%expressions(k)=p%expressions(e)
    p%expressions(k)%args(1)=e;p%expressions(e)%args(1)=k
    call execute_program(p,d)
    call expect(d%code/=0,'indirect operand cycle rejected')
    ! Nonfinite public-IR values are rejected only when evaluated. KIND remains
    ! a structural inquiry and does not read an otherwise valid data value.
    do family=1,4
      name=trim(names(family))
      do j=1,2
        call parse_subset('program p'//nl//'print *,'//name//'(2d0)'//nl//'end program',p,d)
        call expect(d%code==0,'nonfinite fixture parse')
        e=p%code(1)%items(1);a=p%expressions(e)%args(1)
        if(j==1)p%expressions(a)%value%r=ieee_value(0d0,ieee_quiet_nan)
        if(j==2)p%expressions(a)%value%r=ieee_value(0d0,ieee_positive_inf)
        call execute_program(p,d)
        call expect(d%code/=0,'nonfinite evaluated value rejected')
        k=p%ne+1;p%ne=k
        p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
        d=diagnostic_t();call evaluate_constant(p,k,v,d)
        call expect(d%code==0.and.v%i==8,'KIND does not evaluate nonfinite data')
      end do
    end do
    ! Boundary semantics independent of GNU's narrow-result runtime lowering.
    call value_check('aint(1.999999999999d0,4)',1.0_real64,4)
    call value_check('anint(0.499999999999d0,4)',0.0_real64,4)
    call value_check('anint(-0.5d0)',-1.0_real64,8)
    call value_check('aint(huge(1d0))',huge(1d0),8)
    call value_check('anint(huge(1.0))',real(huge(1.0),real64),4)
    call value_check('acosh(1d0)',0.0_real64,8)
    print *, 'PASS: real rounding/inverse independent assertions:',checks
contains
    subroutine value_check(text,want,kind_value)
      character(*),intent(in)::text
      real(real64),intent(in)::want
      integer,intent(in)::kind_value
      integer::index
      call parse_subset('program p'//nl//'print *,'//text//nl//'end program',p,d)
      call expect(d%code==0,'boundary parse')
      index=p%code(1)%items(1)
      call evaluate_constant(p,index,v,d)
      call expect(d%code==0,'boundary evaluation')
      call expect(v%r==want.and.v%real_kind==kind_value.and.v%tag==ty_real,'boundary result')
    end subroutine
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,name,rk,form,mutation,label
      if(allocated(d%message))print *,d%message
      error stop 'real rounding/inverse invariant failure'
    end subroutine
end program
