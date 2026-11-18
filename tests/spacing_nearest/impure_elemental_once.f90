module m
integer::calls=0
contains
impure elemental real function f(n)
integer,intent(in)::n
calls=calls+1
f=real(n)
end function
end module
program p
use m
implicit none
print *,nearest(f([1,2,3]),1.)>[1.,2.,3.]
print *,calls
print *,spacing(f([1,2,3]))>0
print *,calls
end program
