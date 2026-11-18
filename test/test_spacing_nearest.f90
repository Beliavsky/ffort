! SPDX-License-Identifier: MIT
program test_spacing_nearest
    use, intrinsic :: iso_fortran_env, only:int64,real64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:evaluate_constant,execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,expr,call_text,decl,first,second,name,suffix
    integer::family,t,rk,form,mutation,e,a,j,k,checks
    checks=0
    do family=1,2
      select case(family)
      case(1);name='spacing'
      case(2);name='nearest'
      end select
      do t=ty_real,ty_real
        do rk=4,8,4
          suffix=''
          if(rk==8)suffix='_8'
          first='5';second='3';decl='integer'
          if(t==ty_real)then
            first='5.0';second='3.0';decl='real'
          end if
          first=first//suffix;second=second//suffix
          if(rk==8)decl=decl//'(8)'
          do form=1,3
            call_text=name//'('//first
            if(form==3)call_text=name//'(z'
            if(family==2)call_text=call_text//','//second
            call_text=call_text//')';expr=call_text
            if(form==2)expr='kind('//call_text//')'
            source='program p'//nl//'implicit none'//nl
            if(form==3)source=source//decl//'::z(0)'//nl
            source=source//'print *,'//expr//nl//'end program'
            do mutation=0,21
              if(family==1.and.mutation>16)cycle
              call parse_subset(source,p,d)
              call expect(d%code==0,'baseline parse')
              e=0
              do j=1,p%ne
                if(p%expressions(j)%op==name)e=j
              end do
              call expect(e>0,'call retained')
              a=p%expressions(e)%args(1)
              select case(mutation)
              case(1);p%expressions(e)%typ=ty_logical
              case(2);p%expressions(e)%real_kind=12-rk
              case(3);p%expressions(e)%rank=1-p%expressions(e)%rank
              case(4);p%expressions(e)%extent=77_int64
              case(5);p%expressions(e)%dims=[1_int64,2_int64,1_int64]
              case(6);p%expressions(e)%intrinsic_mask=1
              case(7);p%expressions(e)%args=[integer::]
              case(8);p%expressions(e)%args=[p%expressions(e)%args,a]
              case(9);deallocate(p%expressions(e)%args)
              case(10);p%expressions(e)%args(1)=0
              case(11);p%expressions(e)%args(1)=p%ne+1
              case(12);p%expressions(e)%args(1)=e
              case(13);p%expressions(a)%typ=ty_logical
              case(14);p%expressions(a)%real_kind=12-rk
              case(15);p%expressions(e)%real_kind=16
              case(16);p%expressions(a)%rank=4
              case(17);p%expressions(p%expressions(e)%args(2))%typ=ty_integer
              case(18);p%expressions(p%expressions(e)%args(2))%real_kind=16
              case(19);p%expressions(e)%args(2)=0
              case(20);p%expressions(e)%args(2)=e
              case(21);p%expressions(p%expressions(e)%args(2))%rank=4
              end select
              call verify_frontend(source,p,d)
              call expect((d%code==0).eqv.(mutation==0),'adapter metadata')
              d=diagnostic_t()
              call execute_program(p,d)
              call expect((d%code==0).eqv.(mutation==0),'runtime metadata')
              d=diagnostic_t();k=p%ne+1;p%ne=k
              p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
              call evaluate_constant(p,k,v,d)
              call expect((d%code==0).eqv.(mutation==0),'unevaluated KIND metadata')
              if(mutation==0)call expect(v%i==rk,'kind preserved')
              if(form==3)cycle
              d=diagnostic_t()
              call evaluate_constant(p,e,v,d)
              call expect((d%code==0).eqv.(mutation==0),'constant metadata')
              if(mutation==0)then
                call expect(v%tag==t.and.v%real_kind==rk,'value type/kind')
                if(family==1)then
                  if(rk==4)call expect(v%r==real(spacing(5.0),real64),'SPACING real4 value')
                  if(rk==8)call expect(v%r==spacing(5d0),'SPACING real8 value')
                else
                  if(rk==4)call expect(v%r==real(nearest(5.0,3.0),real64),'NEAREST real4 value')
                  if(rk==8)call expect(v%r==nearest(5d0,3d0),'NEAREST real8 value')
                end if
              end if
            end do
          end do
        end do
      end do
    end do
    print *,'PASS: SPACING/NEAREST independent assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,'FAIL ',label,' family,type,kind,form,mutation:',family,t,rk,form,mutation
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
