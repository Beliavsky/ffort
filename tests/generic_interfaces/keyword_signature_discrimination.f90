module operations
implicit none
interface choose
module procedure integers,reals
end interface
contains
integer function integers(left,right) result(y)
integer,intent(in)::left
real,intent(in)::right
y=left+int(right)
end function
integer function reals(left,right) result(y)
real,intent(in)::left
integer,intent(in)::right
y=int(left)*10+right
end function
end module
program main
use operations
implicit none
print *,choose(right=2.5,left=3),choose(right=2,left=3.5)
end program
