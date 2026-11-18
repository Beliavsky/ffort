module m
implicit none
contains
pure elemental integer function twice(i) result(answer)
integer,intent(in)::i
answer=2*i
end function
end module
program p
use m
implicit none
integer::x(3),y(3)
x=[1,2,3]
y=twice((x([3,1,3])))
if(.not.all(y==[6,2,6]))error stop 'values'
write(*,'(3i3)')y
end program
