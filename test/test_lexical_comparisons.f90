! SPDX-License-Identifier: MIT
program test_lexical_comparisons
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(3),parameter::names(4)=[character(3)::'lge','lgt','lle','llt']
    character(:),allocatable::source,call_text,name,expr,decl
    integer::family,form,mutation,operand,e,a,k,j,checks
    checks=0
    do family=1,4
      name=names(family)
      do form=1,3
        do operand=1,2
          call_text=name//"('ab','abc')";decl=''
          if(form==3)then
            call_text=name//'(a,b)';decl='character(2)::a(0,2,3),b(0,2,3)'//nl
          end if
          expr=call_text;if(form==2)expr='kind('//expr//')'
          source='program p'//nl//'implicit none'//nl//decl//'print *,'//expr//nl//'end program'
          do mutation=0,24
            call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
            e=0
            do j=1,p%ne
              if(p%expressions(j)%op==name)e=j
            end do
            call expect(e>0,'intrinsic occurrence');a=p%expressions(e)%args(operand)
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_integer
            case(2);p%expressions(e)%real_kind=8
            case(3);p%expressions(e)%rank=4
            case(4);p%expressions(e)%extent=77
            case(5);p%expressions(e)%dims=[1_int64,2_int64,3_int64]
            case(6);p%expressions(e)%intrinsic_mask=3
            case(7);p%expressions(e)%args=[integer::]
            case(8);p%expressions(e)%args=[a]
            case(9);p%expressions(e)%args=[p%expressions(e)%args,a]
            case(10);deallocate(p%expressions(e)%args)
            case(11);p%expressions(e)%args(operand)=0
            case(12);p%expressions(e)%args(operand)=p%ne+1
            case(13);p%expressions(e)%args(operand)=e
            case(14);p%expressions(a)%typ=ty_integer
            case(15);p%expressions(a)%real_kind=8
            case(16);p%expressions(a)%rank=4
            case(17);p%expressions(a)%extent=99
            case(18);p%expressions(a)%dims=[9_int64,9_int64,9_int64]
            case(19);p%expressions(a)%character_len=65537
            case(20)
              if(form==3)then
                p%symbols(p%expressions(a)%symbol)%real_kind=8
              else
                p%expressions(a)%value%real_kind=8
              end if
            case(21)
              if(form==3)then
                p%symbols(p%expressions(a)%symbol)%character_len=3
              else
                p%expressions(a)%value%tag=ty_integer
              end if
            case(22)
              if(form==3)then
                p%symbols(p%expressions(a)%symbol)%typ=ty_integer
              else
                deallocate(p%expressions(a)%value%s)
              end if
            case(23)
              if(form==3)then
                p%symbols(p%expressions(a)%symbol)%rank=1
              else
                p%expressions(a)%value%s='abcd'
              end if
            case(24);p%expressions(e)%character_len=0
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter guard')
            d=diagnostic_t();call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime guard')
            k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t();call evaluate_constant(p,k,v,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND guard')
            if(mutation==0)call expect(v%i==4,'default LOGICAL kind')
          end do
        end do
      end do
    end do
    ! Data outside the bounded ASCII repertoire is rejected even after the
    ! deciding prefix. KIND must not inspect these values.
    do family=1,4
      name=names(family)
      do operand=1,2
        call parse_subset('program p'//nl//'print *,'//name//"('aa','zz')"//nl//'end program',p,d)
        call expect(d%code==0,'nonASCII fixture')
        e=p%code(1)%items(1);a=p%expressions(e)%args(operand)
        p%expressions(a)%value%s(2:2)=achar(128)
        call execute_program(p,d);call expect(d%code/=0,'nonASCII data rejected')
        k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
        d=diagnostic_t();call evaluate_constant(p,k,v,d)
        call expect(d%code==0.and.v%i==4,'KIND does not inspect nonASCII data')
      end do
    end do
    ! Cycles through a CHARACTER expression are rejected without repeatedly
    ! starting fresh recursion marks; an acyclic shared child remains legal.
    call parse_subset('program p'//nl//"print *,lge('a'//'b','ab')"//nl//'end program',p,d)
    call expect(d%code==0,'CHARACTER cycle fixture')
    e=p%code(1)%items(1);a=p%expressions(e)%args(1)
    p%expressions(a)%left=a
    call execute_program(p,d);call expect(d%code/=0,'indirect CHARACTER cycle rejected')
    call parse_subset('program p'//nl//"print *,lge('a'//'b','ab')"//nl//'end program',p,d)
    e=p%code(1)%items(1);a=p%expressions(e)%args(1)
    p%expressions(e)%args(2)=a
    call evaluate_constant(p,e,v,d)
    call expect(d%code==0.and.v%l,'shared CHARACTER operand DAG accepted')
    ! Independent integer-code oracle for all128*128 ASCII one-character pairs.
    ! Evaluate one canonical source and vary only the two data values.
    do family=1,4
      name=names(family)
      call parse_subset('program p'//nl//'print *,'//name//"('a','b')"//nl//'end program',p,d)
      call expect(d%code==0,'ASCII oracle fixture')
      e=p%code(1)%items(1);a=p%expressions(e)%args(1);k=p%expressions(e)%args(2)
      do j=0,127
        do operand=0,127
          p%expressions(a)%value%s=achar(j);p%expressions(k)%value%s=achar(operand)
          d=diagnostic_t();call evaluate_constant(p,e,v,d)
          call expect(d%code==0,'ASCII pair evaluation')
          select case(family)
          case(1);call expect(v%l.eqv.(j>=operand),'LGE integer-code oracle')
          case(2);call expect(v%l.eqv.(j>operand),'LGT integer-code oracle')
          case(3);call expect(v%l.eqv.(j<=operand),'LLE integer-code oracle')
          case(4);call expect(v%l.eqv.(j<operand),'LLT integer-code oracle')
          end select
        end do
      end do
    end do
    print *, 'PASS: independent lexical assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,name,form,operand,mutation,label
      if(allocated(d%message))print *,d%message
      error stop 'lexical invariant failure'
    end subroutine
end program
