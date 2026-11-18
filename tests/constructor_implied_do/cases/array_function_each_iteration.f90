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
integer::i,x(2),a(6)
x=[1,2]
a=[(tick(x+i),i=1,3)]
print *,a,calls
end program
