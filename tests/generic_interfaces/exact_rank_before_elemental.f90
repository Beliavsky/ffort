module operations
implicit none

interface twice
module procedure scalar,vector
end interface
contains
elemental integer function scalar(x) result(y)
integer,intent(in)::x
y=x+100
end function
integer function vector(x) result(y)
integer,intent(in)::x(:)
y=sum(x)+200
end function
end module
program main
use operations
implicit none
integer::a(3)=[1,2,3]
print *,twice(4),twice(a)
end program
