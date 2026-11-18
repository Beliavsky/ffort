module m
implicit none
contains
pure function concat_char_vec(xx,yy) result(zz)
character (len=*), intent(in) :: xx(:),yy(:)
character (len=max(len(xx),len(yy))) :: zz(size(xx)+size(yy))
integer                              :: nx
nx = size(xx)
zz(:nx)   = xx
zz(nx+1:) = yy
end function concat_char_vec
end module m
program test
use m
implicit none
character(2) :: a(3)=["aa","bb","cc"]
character(4) :: b(2)=["dddd","eeee"]
character(4) :: c(4)
c=concat_char_vec(a(3:1:-2),b)
print *,c(1)//"|",c(2)//"|",c(3)//"|",c(4)//"|"
end program test
