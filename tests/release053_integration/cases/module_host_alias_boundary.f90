module m
implicit none
integer::x(3)
contains
subroutine consume(a)
integer,intent(in)::a(:)
write(*,'(i3)')sum(a)+x(1)
end subroutine
end module
program p
use m
implicit none
x=[1,2,3]
call consume(x([3,1]))
end program
