module utility_slice
implicit none
private
public :: dp,long_int,i64,concat_char_vec
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
pure function concat_char_vec(xx,yy) result(zz)
character (len=*), intent(in) :: xx(:),yy(:)
character (len=max(len(xx),len(yy))) :: zz(size(xx)+size(yy))
integer                              :: nx
nx = size(xx)
zz(:nx)   = xx
zz(nx+1:) = yy
end function concat_char_vec

end module
program test_slice
use utility_slice
implicit none
print *, concat_char_vec(["dog","cat"],["four","five"])
end program
