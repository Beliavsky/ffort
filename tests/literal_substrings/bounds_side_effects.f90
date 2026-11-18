module m
implicit none
integer::calls=0
contains
integer function bound(x) result(y)
integer,intent(in)::x
calls=calls+1
y=x
end function
end module
program p
use m
implicit none
character(3)::s
s='abcd'(bound(2):bound(4))
if(s/='bcd'.or.calls/=2) error stop 1
if(len('abcd'(bound(2):bound(3)))/=2.or.calls/=4) error stop 2
if(kind('abcd'(bound(1):bound(1)))/=1.or.calls/=4) error stop 3
print *, 'side effects'
end program
