module m
implicit none
interface inc
module procedure procedure
end interface
contains
integer function procedure(x) result(y)
integer,intent(in)::x
y=x+1
end function
end module
program p
use m
implicit none
if(inc(2)/=3) error stop 1
print *, 'module procedure clause'
end program
