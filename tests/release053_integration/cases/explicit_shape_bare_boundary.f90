module m
implicit none
contains
subroutine consume(a)
integer,intent(in)::a(2)
write(*,'(2i3)')a
end subroutine
end module
program p
use m
implicit none
integer::x(3)
x=[1,2,3]
call consume(x([3,1]))
end program
