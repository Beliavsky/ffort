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
integer::i,a(4)
a=[(i,i=tick(1),tick(4),tick(1))]
print *,a,calls
end program
