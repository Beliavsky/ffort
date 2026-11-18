module m
implicit none
type box
integer::n=0
contains
procedure::accept
end type
contains
subroutine accept(self,v)
class(box),intent(in)::self
character(*),intent(in)::v(:)
if(any(v/=["ef","ab","ef"]))error stop "value"
end subroutine
end module
program main
use m
implicit none
type(box)::b
character(2)::x(3)=["ab","cd","ef"]
call b%accept((x([3,1,3])))
end program
