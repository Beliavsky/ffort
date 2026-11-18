module strings
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
end module strings
program test
use strings
implicit none
character(2) :: a(2)=["ab","cd"]
character(4) :: b(2)=["EFGH","IJKL"]
character(4) :: c(4)
c=concat_char_vec(a,b)
print *,c(1)//"|",c(2)//"|",c(3)//"|",c(4)//"|"
print *,len(a),len(b),len(c),size(c)
end program test
