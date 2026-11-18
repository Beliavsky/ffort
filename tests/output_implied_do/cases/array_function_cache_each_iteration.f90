module m
implicit none
integer::calls=0
contains
impure elemental integer function tick(x) result(r)
integer,intent(in)::x
calls=calls+1
r=x
end function
end module
program main
use m
implicit none
integer::i,a(3)
a=[1,2,3]
print *, (tick(a+i),i=1,3)
print *,calls
end program
