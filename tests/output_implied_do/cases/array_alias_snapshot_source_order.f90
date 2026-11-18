module m
implicit none
integer::a(2)
contains
impure elemental integer function bump(x) result(r)
integer,intent(in)::x
a=a+1
r=x
end function
end module
program main
use m
implicit none
integer::i
a=[10,20]
print *, (a,bump(i),i=1,2)
print *,a
end program
