module m
implicit none
contains
recursive integer function f(n) result(r)
integer,intent(in)::n
integer::i,a(2)
i=100+n
if(n==0) then
r=0
else
a=[(i+f(n-1),i=1,2)]
r=sum(a)+i
end if
end function
end module
program main
use m
implicit none
print *,f(2)
end program
