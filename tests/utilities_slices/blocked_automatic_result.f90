module utility_slice
implicit none
private
public :: dp,long_int,i64,normalize
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
function normalize(xx) result(yy)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx))
yy = xx/max(sum(abs(xx)),tiny_real)
end function normalize

end module
program test_slice
use utility_slice
implicit none
print *, normalize([1.0_dp,2.0_dp,3.0_dp])
end program
