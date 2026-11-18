module utility_slice
implicit none
private
public :: dp,long_int,i64,frac_true
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
function frac_true(xx) result(yy)
logical, intent(in) :: xx(:)
real(kind=dp)       :: yy
yy = count(xx)/dble(max(1,size(xx)))
end function frac_true

end module
program test_slice
use utility_slice
implicit none
print *, frac_true([.true.,.false.])
end program
