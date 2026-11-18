module m
implicit none
contains
function indices() result(answer)
integer::answer(2)
write(*,'(a)')'effect'
answer=[3,1]
end function
end module
program p
use m
implicit none
integer::a(3),b(2)
a=[1,2,3]
b=a(indices())
write(*,'(2i3)')b
end program
