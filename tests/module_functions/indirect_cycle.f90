module m

contains
recursive function fa(x) result(y)
integer,intent(in) :: x
integer :: y
y=fb(x)
end function fa
recursive function fb(x) result(y)
integer,intent(in) :: x
integer :: y
y=fa(x)
end function fb
end module m
program main
use m
implicit none

print *, fa(3)
end program main
