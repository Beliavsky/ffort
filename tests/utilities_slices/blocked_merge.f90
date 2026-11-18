module utility_slice
implicit none
private
public :: dp,long_int,i64,choose,factorial_long
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
elemental function choose(n,k) result(j)
integer, intent(in)    :: n,k
integer                :: j
integer                :: i
integer(kind=long_int) :: numer,k_
if (k > n) then
   j = 0
   return
end if
if (n < 1) then
   j = 1
   return
end if
if (n == k .or. k == 0) then
   j = 1
   return
else if (k == 1 .or. k == n-1) then
   j = n
   return
end if
k_ = merge(n-k,k,k > n/2) 
numer = 1
do i=n-k_+1,n
   numer = numer*i
end do
j = numer/factorial_long(k_)
! print*,n,k,numer,factorial(k),j
end function choose

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
print *, choose(4,[0,1,2,3,4,5])
end program
