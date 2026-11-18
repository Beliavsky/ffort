module m
implicit none
integer::calls=0
contains
impure elemental integer function pick(i) result(value)
integer,intent(in)::i
calls=calls+1
value=i
end function
end module
program p
use m
implicit none
integer::a(3,2),b(2,2)
a=reshape([1,2,3,4,5,6],[3,2])
b=a(pick([3,1]),:)
if(calls/=2) error stop 1
print *,b,calls
end program
