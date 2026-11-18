program p
implicit none
integer :: a,b
a=3;b=0
call move_alloc(a,b)
if(a/=3.or.b/=4)error stop 1
contains
subroutine move_alloc(x,y)
integer,intent(in) :: x
integer,intent(out) :: y
y=x+1
end subroutine
end program
