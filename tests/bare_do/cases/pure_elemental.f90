module m
implicit none
contains
elemental integer function f(k) result(v)
integer,intent(in)::k
integer::n
v=0
n=0
do
n=n+1
v=v+n
if(n==k) exit
end do
end function
end module
program p
use m
implicit none

print *,f([1,3,5])
end program
