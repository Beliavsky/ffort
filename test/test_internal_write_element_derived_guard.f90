program test_internal_write_element_derived_guard
 use,intrinsic::iso_fortran_env,only:int64
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program
 implicit none
 type(program_t)::p
 type(diagnostic_t)::d
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source= &
        'module m'//nl// &
        'implicit none'//nl// &
        'character(4)::storage(1)'//nl// &
        'type::box'//nl// &
        'integer::n=7'//nl// &
        'contains'//nl// &
        'procedure::write_box'//nl// &
        'generic::write(formatted)=>write_box'//nl// &
        'end type'//nl// &
        'contains'//nl// &
        'subroutine write_box(dtv,unit,iotype,v_list,iostat,iomsg)'//nl// &
        'class(box),intent(in)::dtv'//nl// &
        'integer,intent(in)::unit'//nl// &
        'character(*),intent(in)::iotype'//nl// &
        'integer,intent(in)::v_list(:)'//nl// &
        'integer,intent(out)::iostat'//nl// &
        'character(*),intent(inout)::iomsg'//nl// &
        'storage=''BAD!'''//nl// &
        'write(unit,''(a)'',iostat=iostat,iomsg=iomsg)''DT'''//nl// &
        'end subroutine'//nl// &
        'end module'//nl// &
        'program main'//nl// &
        'use m'//nl// &
        'implicit none'//nl// &
        'storage=''old!'''//nl// &
        'write(storage(1),''(a)'')''X'''//nl// &
        'print ''(a)'',storage'//nl// &
        'end program'//nl
 integer::which,i,pc,e,checks
 checks=0
 do which=1,2
  call parse_subset(source,p,d)
  call expect(d%code==0,'original parses')
  pc=0
  do i=1,p%nc
   if(p%code(i)%op==op_write_internal)pc=i
  end do
  call expect(pc>0,'internal WRITE found')
  e=p%code(pc)%items(1);p%code(pc)%format='(dt)'
  p%expressions(e)%value%tag=ty_derived_base+1
  allocate(p%expressions(e)%value%record)
  allocate(p%expressions(e)%value%record%components(1),p%expressions(e)%value%record%component_defined(1))
  p%expressions(e)%value%record%components(1)=component_value_t(tag=ty_integer,i=7_int64)
  p%expressions(e)%value%record%component_defined=.true.
  if(which==2)p%expressions(e)%typ=ty_derived_base+1
  call verify_frontend(source,p,d)
  call expect(d%code/=0,'adapter rejects forged derived output')
  d=diagnostic_t()
  call execute_program(p,d,max_steps=10000_int64)
  call expect(d%code==2,'runtime rejects before defined callback')
  if(which==1)then
   call expect(d%message=='derived values are unsupported in internal WRITE array elements','cached value guard')
  else
   call expect(d%message=='invalid internal WRITE element expression effects','typed item guard')
  end if
 end do
 print *,'PASS: internal WRITE derived output guards:',checks
contains
 subroutine expect(ok,label)
 logical,intent(in)::ok
 character(*),intent(in)::label
 checks=checks+1
 if(ok)return
 print *,label,which
 if(allocated(d%message))print *,d%message
 error stop 1
 end subroutine
end program
