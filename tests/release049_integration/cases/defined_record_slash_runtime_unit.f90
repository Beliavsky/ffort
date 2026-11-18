module m
implicit none
type::box
integer::a,b=7
character(3)::s="DT"
contains
procedure::emit
generic::write(formatted)=>emit
end type
contains
subroutine emit(dtv,unit,iotype,v_list,iostat,iomsg)
class(box),intent(in)::dtv
integer,intent(in)::unit
character(*),intent(in)::iotype
integer,intent(in)::v_list(:)
integer,intent(out)::iostat
character(*),intent(inout)::iomsg
write(unit,"(a,i0)",iostat=iostat,iomsg=iomsg)dtv%s,dtv%b
end subroutine
end module
program p
use m
use iso_fortran_env, only: output_unit
implicit none
type(box)::x,y
integer::u
x%a=1
y%a=2
y%s="QQ"
u=output_unit
write(u,"(dt,/,dt)")x,y
end program
