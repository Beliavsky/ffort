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
integer::i
print *, (tick(i),i=tick(1),tick(3),tick(1))
print *,calls,i
end program
