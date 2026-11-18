! SPDX-License-Identifier: MIT
! Independent source-only adapter tests. No candidate library has been linked.
program test_dynamic_character_constructor_adapter
 use, intrinsic :: iso_fortran_env, only:error_unit
 use fi_ir
 use fi_parser, only:parse_subset
 use fi_frontend, only:verify_frontend
 implicit none
 character(*),parameter::nl=new_line('a')
 integer::checks
 checks=0
 call audit('character(*),intent(in)::x,z', &
  'character(len(x))::a(3)','a=[x,(x,i=1,2)]',"call f('ab','cd')")
 call audit('character(*),intent(in)::x(:),z(:)', &
  'character(len(x))::a(3*size(x))','a=[x,(x,i=1,2)]',"call f(['ab','cd'],['ef','gh'])")
 call audit('character(*),intent(in)::x,z', &
  'character(len(x))::a(5)','a=[x,((x,j=1,2),i=1,2)]',"call f('ab','cd')")
 write(error_unit,'(a,i0)')'dynamic CHARACTER constructor adapter checks: ',checks
contains
 subroutine audit(declaration,result_decl,assignment,invocation)
  character(*),intent(in)::declaration,result_decl,assignment,invocation
  character(:),allocatable::source,changed
  type(program_t)::p,q
  type(diagnostic_t)::d
  integer::n,root,loop,leaf,xsym,zsym,bound,which,tmp,pos
  source='module m'//nl//'implicit none'//nl//'contains'//nl// &
   'subroutine f(x,z)'//nl//declaration//nl//'integer::i,j,k'//nl// &
   result_decl//nl//assignment//nl//'end subroutine'//nl//'end module'//nl// &
   'program p'//nl//'use m'//nl//invocation//nl//'end program'
  call parse_subset(source,p,d)
  call expect(d%code==0,'baseline parse',d)
  call verify_frontend(source,p,d)
  call expect(d%code==0,'baseline adapter',d)
  root=0;loop=0;leaf=0;xsym=0;zsym=0
  do n=1,p%ns
   if(p%symbols(n)%name=='x')xsym=n
   if(p%symbols(n)%name=='z')zsym=n
  end do
  do n=1,p%ne
   if(p%expressions(n)%kind==ex_constructor.and.p%expressions(n)%typ==ty_character.and. &
      p%expressions(n)%scope>0)then
    if(allocated(p%expressions(n)%args))then
     if(size(p%expressions(n)%args)==2)root=n
    endif
   endif
   if(p%expressions(n)%kind==ex_constructor_do)loop=n
   if(p%expressions(n)%kind==ex_variable.and.p%expressions(n)%symbol==xsym)leaf=n
  enddo
  call expect(min(root,loop,leaf,xsym,zsym)>0,'baseline identities',d)
  bound=p%expressions(loop)%right
  call expect(p%expressions(root)%character_len==-1,'root length is descriptor-derived',d)
  do which=1,19
   q=p
   select case(which)
   case(1);q%expressions(root)%character_len=0
   case(2);q%expressions(root)%character_len=2
   case(3);q%expressions(loop)%character_len=0
   case(4);q%expressions(loop)%character_len=2
   case(5);q%expressions(leaf)%character_len=0
   case(6);q%expressions(leaf)%character_len=2
   case(7);q%expressions(root)%length_expr=bound
   case(8);q%expressions(loop)%length_expr=bound
   case(9);q%expressions(leaf)%symbol=zsym
   case(10)
    do n=1,q%ne
     if(q%expressions(n)%kind==ex_variable.and.q%expressions(n)%symbol==xsym) &
      q%expressions(n)%symbol=zsym
    enddo
   case(11);q%expressions(root)%args=q%expressions(root)%args(2:1:-1)
   case(12);q%expressions(loop)%line=q%expressions(loop)%line+1
   case(13);q%expressions(loop)%column=q%expressions(loop)%column+1
   case(14);q%expressions(leaf)%kind=ex_call
   case(15);q%expressions(leaf)%rank=1-q%expressions(leaf)%rank
   case(16);q%expressions(bound)%value%i=3
   case(17);q%expressions(loop)%args=[leaf]
    ! Change this to a genuine other descriptor even if leaf was already its body.
    q%expressions(leaf)%symbol=zsym
   case(18);q%symbols(xsym)%character_len=2
   case(19);q%expressions(root)%op='character';q%expressions(root)%character_len=2
   end select
   d=diagnostic_t();call verify_frontend(source,q,d)
   call expect(d%code/=0,'mutated metadata/source binding rejected',d)
  enddo
  changed=source;pos=index(changed,'a=[x,');changed(pos+3:pos+3)='z'
  d=diagnostic_t();call verify_frontend(changed,p,d)
  call expect(d%code/=0,'changed source leaf rejected',d)
  changed=source;pos=index(changed,'i=1,2');changed(pos:pos)='k'
  d=diagnostic_t();call verify_frontend(changed,p,d)
  call expect(d%code/=0,'changed source implied-DO owner rejected',d)
 end subroutine
 subroutine expect(ok,label,d)
  logical,intent(in)::ok
  character(*),intent(in)::label
  type(diagnostic_t),intent(in)::d
  checks=checks+1
  if(ok)return
  write(error_unit,'(a,i0,2a)')'FAIL ',checks,': ',label
  if(allocated(d%message))write(error_unit,'(a)')d%message
  stop 1
 end subroutine
end program
