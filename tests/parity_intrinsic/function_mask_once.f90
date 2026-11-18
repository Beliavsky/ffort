module m
integer::calls=0
contains
impure elemental logical function mask(n)
integer,intent(in)::n
calls=calls+1
mask=n>1
end function
end module
program p
use m
implicit none
print *,parity(mask([1,2,3]))
print *,calls
end program
