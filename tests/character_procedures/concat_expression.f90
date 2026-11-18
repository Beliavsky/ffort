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
character(2) :: a(2)=["aa","bb"]
character(4) :: c(3)
c=concat_char_vec("!"//a,[character(4)::"xyz"])
print *,c(1)//"|",c(2)//"|",c(3)//"|"
end program test
