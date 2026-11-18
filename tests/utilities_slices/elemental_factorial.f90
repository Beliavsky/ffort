module utility_slice
implicit none
private
public :: dp,long_int,i64,factorial
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function factorial(n) result(ifact)
integer, intent(in) :: n
integer             :: ifact
integer             :: i
ifact = 1
do i=2,n
   ifact = ifact*i
end do
end function factorial

end module
program test_slice
use utility_slice
implicit none
print *, factorial([-1,0,1,2,3,4])
end program
