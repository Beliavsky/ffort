! SPDX-License-Identifier: MIT
program test_pure_internal_write
 use fortfront_compiler,only:compiler_frontend_result_t,compiler_frontend_options_t, &
 compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT
 implicit none
 character(*),parameter::nl=new_line('a')
 type(compiler_frontend_result_t)::front
 type(compiler_frontend_options_t)::opts
 character(:),allocatable::src,decl,stmt
 integer::k,checks
 checks=0
 opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
 opts%standardize=.false.;opts%run_semantics=.true.
 do k=1,14
 decl='';stmt=''
 select case(k)
 case(1);stmt='write(s,"(i2.2)")n'
 case(2);decl='character(2)::t';stmt='write(t,"(i2.2)")n'//nl//'s=t'
 case(3);decl='character(8)::fmt';stmt='fmt="(i2.2)"'//nl//'write(s,fmt)n'
 case(4);stmt='if(n>0)then'//nl//'write(s,"(i2.2)")n'//nl//'else'//nl//'s="00"'//nl//'end if'
 case(5);stmt='write(*,"(i2.2)")n'//nl//'s="07"'
 case(6);decl='integer::u';stmt='u=6'//nl//'write(u,"(i2.2)")n'//nl//'s="07"'
 case(7);stmt='write(6,"(i2.2)")n'//nl//'s="07"'
 case(8);decl='character(2),parameter::t="00"';stmt='write(t,"(i2.2)")n'//nl//'s="07"'
 case(9);decl='character(2),save::t';stmt='write(t,"(i2.2)")n'//nl//'s="07"'
 case(10);decl='character(2)::t="00"';stmt='write(t,"(i2.2)")n'//nl//'s="07"'
 case(11);stmt='if(n>0)then'//nl//'write(*,"(i2.2)")n'//nl//'end if'//nl//'s="07"'
 case(12);decl='integer::i';stmt='do i=1,1'//nl//'write(*,"(i2.2)")n'//nl//'end do'//nl//'s="07"'
 case(13);decl='character(2),pointer::t';stmt='write(t,"(i2.2)")n'//nl//'s="07"'
 case(14);decl='character(2),volatile::t';stmt='write(t,"(i2.2)")n'//nl//'s="07"'
 end select
 src='program p'//nl//'implicit none'//nl//'print "(a)",mark(7)'//nl//'contains'//nl// &
  'pure function mark(n) result(s)'//nl//'integer,intent(in)::n'//nl//'character(2)::s'//nl// &
  decl//nl//stmt//nl//'end function'//nl//'end program'
 call compile_frontend_from_string(src,front,opts)
 call require(front%success().eqv.(k<=4),'local/external WRITE classification')
 end do
 ! Same spelling in another procedure must not turn an integer external unit
 ! into a CHARACTER internal file; host association is not a local definition.
 src='program p'//nl//'implicit none'//nl//'character(2)::t'//nl//'print "(a)",mark(7)'//nl// &
 'contains'//nl//'subroutine other()'//nl//'character(2)::u'//nl//'end subroutine'//nl// &
 'pure function mark(n) result(s)'//nl//'integer,intent(in)::n'//nl//'character(2)::s'//nl// &
 'integer::u'//nl//'u=6'//nl//'write(u,"(i2.2)")n'//nl//'s="07"'//nl//'end function'//nl//'end program'
 call compile_frontend_from_string(src,front,opts)
 call require(.not.front%success(),'another scope cannot provide the unit type')
 src='program p'//nl//'implicit none'//nl//'character(2)::t'//nl//'print "(a)",mark(7)'//nl// &
 'contains'//nl//'pure function mark(n) result(s)'//nl//'integer,intent(in)::n'//nl//'character(2)::s'//nl// &
 'write(t,"(i2.2)")n'//nl//'s="07"'//nl//'end function'//nl//'end program'
 call compile_frontend_from_string(src,front,opts)
 call require(.not.front%success(),'host variable is not a writable local file')
 print *,'PASS: PURE internal WRITE producer checks:',checks
contains
 subroutine require(ok,label)
 logical,intent(in)::ok
 character(*),intent(in)::label
 if(.not.ok)then
  print *,label,k
  error stop 'PURE internal WRITE producer assertion'
 end if
 checks=checks+1
 end subroutine
end program
