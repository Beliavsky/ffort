module m

contains
function answer() result(y)
integer :: y
y=42
end function answer
end module m
program main
use m
implicit none

print *, answer()
end program main
