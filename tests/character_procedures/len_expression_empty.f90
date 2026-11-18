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
character(2)::a(0)
character(4)::b(0)
print *,len(concat_char_vec(a,b)),size(concat_char_vec(a,b))
end program test
