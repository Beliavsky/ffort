module utility_slice
implicit none
private
public :: dp,long_int,i64,factorial_long
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function factorial_long(n) result(ifact)
integer(kind=long_int), intent(in) :: n
integer(kind=long_int)             :: ifact
integer(kind=long_int)             :: i
ifact = 1
do i=2,n
   ifact = ifact*i
end do
end function factorial_long

end module
program test_slice
use utility_slice
implicit none
print *, factorial_long(20_i64)
end program
