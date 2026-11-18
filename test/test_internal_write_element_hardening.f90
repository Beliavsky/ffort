program test_internal_write_element_hardening
 use,intrinsic::iso_fortran_env,only:int64
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program
 implicit none
 type(program_t)::p
 type(diagnostic_t)::d
 character(*),parameter::nl=new_line('a')
 character(:),allocatable::source
 integer::mode,which,i,pc,e,q,checks
 checks=0
 do mode=1,2
  source='program main'//nl//'implicit none'//nl//'character(4)::a(2)'//nl
  if(mode==2)source=source//'integer::i'//nl//'i=2'//nl
  if(mode==1)then
   source=source//"write(a(2),'(i2.2)')7"//nl//'end program'//nl
  else
   source=source//"write(a(i),'(i2.2)')7"//nl//'end program'//nl
  end if
  do which=1,6
   if(mode==2.and.which>2)exit
   call parse_subset(source,p,d)
   call expect(d%code==0,'original parses')
   pc=0
   do i=1,p%nc
    if(p%code(i)%op==op_write_internal)pc=i
   end do
   call expect(pc>0,'WRITE located')
   e=p%code(pc)%a;q=p%expressions(e)%left
   if(mode==1)then
    select case(which)
    case(2);p%expressions(q)%value%real_kind=8
    case(3);p%expressions(q)%real_kind=8
    case(4);p%expressions(q)%dims=[1_int64,0_int64,0_int64]
    case(5);p%expressions(q)%extent=1_int64
    case(6);p%expressions(q)%value%tag=ty_real
    end select
   else
    if(which==2)p%expressions(q)%real_kind=8
   end if
   call verify_frontend(source,p,d)
   call expect((d%code==0).eqv.(which==1),'adapter rejects corrupted index')
   d=diagnostic_t()
   call execute_program(p,d,max_steps=10000_int64)
   if(which==1)then
    call expect(d%code==0,'runtime original executes')
   else
    call expect(d%code==2,'runtime independently rejects corrupted index')
   end if
  end do
 end do
 print *,'PASS: internal WRITE index metadata assertions:',checks
contains
 subroutine expect(ok,label)
 logical,intent(in)::ok
 character(*),intent(in)::label
 checks=checks+1
 if(ok)return
 print *,label,mode,which
 if(allocated(d%message))print *,d%message
 error stop 1
 end subroutine
end program
