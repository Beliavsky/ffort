module m
implicit none
integer::calls=0
contains
impure elemental function pick(i) result(j)
integer,intent(in)::i
integer::j
calls=calls+1
j=i
end function
end module
program p
use m
implicit none
integer::a(4),b(3)
a=[10,20,30,40]
b=a(pick([4,1,4]))
if(calls/=3.or.any(b/=[40,10,40]))error stop 1
print '(i0)',1
end program
