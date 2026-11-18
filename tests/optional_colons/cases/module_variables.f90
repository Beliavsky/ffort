module m
implicit none
integer count
real(8) scale
contains
subroutine set_values()
count=3
scale=2.5_8
end subroutine
end module
program p
use m
call set_values()
print *,count,scale
end program
