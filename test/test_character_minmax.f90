! SPDX-License-Identifier: MIT
program test_character_minmax
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
    character(3),parameter::names(2)=[character(3)::'min','max']
    character(:),allocatable::source,call_text,name,expr,decl
    integer::family,form,mutation,operand,e,a,k,j,checks,left_code,right_code,q
    character(:),allocatable::expected,left,right
    character(4),parameter::samples(8)=[character(4)::"", " ","a", "a!", "a b", "ab", " b", "ba"]
    checks=0
    do family=1,2
      name=names(family)
      do form=1,3
        do operand=1,2
          call_text=name//"('ab','abc')";decl=''
          if(form==3)then
            call_text=name//'(a,b)';decl='character(2)::a(0,2,3),b(0,2,3)'//nl
          end if
          expr=call_text;if(form==2)expr='kind('//expr//')'
          source='program p'//nl//'implicit none'//nl//decl//'print *,'//expr//nl//'end program'
          do mutation=0,29
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
            case(9);p%expressions(e)%args=[(a,j=1,17)]
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
            case(25);p%expressions(e)%left=a
            case(26);p%expressions(e)%symbol=1
            case(27);p%expressions(e)%length_expr=a
            case(28);p%expressions(e)%constructor_kind_expr=a
            case(29);p%expressions(e)%triplet(2)=.true.
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter guard')
            d=diagnostic_t();call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime guard')
            k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t();call evaluate_constant(p,k,v,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND guard')
            if(mutation==0)call expect(v%i==1,'default CHARACTER kind')
          end do
        end do
      end do
    end do
    ! An indirect cycle fails even for unevaluated KIND; an acyclic shared
    ! operand remains legal. Neither path reads uninitialized data.
    call parse_subset('program p'//nl//"print *,min('a'//'b','ab')"//nl//'end program',p,d)
    call expect(d%code==0,'cycle fixture')
    e=p%code(1)%items(1);a=p%expressions(e)%args(1)
    p%expressions(a)%left=a
    call execute_program(p,d);call expect(d%code/=0,'indirect cycle rejected')
    call parse_subset('program p'//nl//"print *,max('a'//'b','ab')"//nl//'end program',p,d)
    e=p%code(1)%items(1);a=p%expressions(e)%args(1)
    p%expressions(e)%args(2)=a
    call evaluate_constant(p,e,v,d)
    call expect(d%code==0,'shared operand DAG accepted')
    call expect(v%s=='ab'.and.len(v%s)==2,'shared operand value')
    ! Independent integer collating-code oracle for every 256*256 native
    ! one-byte pair. No host MIN/MAX character intrinsic is used as oracle.
    do family=1,2
      name=names(family)
      call parse_subset('program p'//nl//'print *,'//name//"('a','b')"//nl//'end program',p,d)
      call expect(d%code==0,'byte oracle fixture')
      e=p%code(1)%items(1);a=p%expressions(e)%args(1);k=p%expressions(e)%args(2)
      do left_code=0,255
        do right_code=0,255
          p%expressions(a)%value%s=char(left_code);p%expressions(k)%value%s=char(right_code)
          d=diagnostic_t();call evaluate_constant(p,e,v,d)
          call expect(d%code==0,'byte pair evaluation')
          q=left_code
          if(family==1.and.right_code<q)q=right_code
          if(family==2.and.right_code>q)q=right_code
          call expect(len(v%s)==1.and.ichar(v%s)==q,'native collating-code result')
        end do
      end do
    end do
    ! Multicharacter comparisons verify first-difference, blank padding and
    ! longest-result length, independently for every sample/length pairing.
    do family=1,2
      name=names(family)
      do left_code=1,8
        do right_code=1,8
          do j=0,4
            do operand=0,4
              left=samples(left_code)(:j);right=samples(right_code)(:operand)
              call parse_subset('program p'//nl//'print *,'//name//"('"//left//"','"//right//"')"//nl//'end program',p,d)
              call expect(d%code==0,'padding fixture')
              e=p%code(1)%items(1)
              expected=pad_oracle(left,right,family)
              call evaluate_constant(p,e,v,d)
              call expect(d%code==0,'padding evaluation')
              call expect(len(v%s)==len(expected).and.v%s==expected,'padding exact bytes')
            end do
          end do
        end do
      end do
    end do
    print *, 'PASS: independent CHARACTER MIN/MAX assertions:',checks
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
    function pad_oracle(a,b,family) result(s)
        character(*),intent(in)::a,b
        integer,intent(in)::family
        character(:),allocatable::s
        integer::j,x,y,order,n
        order=0;n=max(len(a),len(b))
        do j=1,n
            x=ichar(' ');y=ichar(' ')
            if(j<=len(a))x=ichar(a(j:j))
            if(j<=len(b))y=ichar(b(j:j))
            if(x<y)order=-1
            if(x>y)order=1
            if(order/=0)exit
        end do
        s=a
        if((family==1.and.order>0).or.(family==2.and.order<0))s=b
        s=s//repeat(' ',n-len(s))
    end function
end program
