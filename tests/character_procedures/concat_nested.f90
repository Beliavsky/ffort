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
character(1) :: a(1)=["a"]
character(2) :: b(1)=["bc"]
character(3) :: c(3)
c=concat_char_vec(concat_char_vec(a,b),["def"])
print *,c(1)//"|",c(2)//"|",c(3)//"|"
end program test
