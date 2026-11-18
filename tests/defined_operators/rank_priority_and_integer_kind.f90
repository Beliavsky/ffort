module ops
implicit none
interface operator(.count.)
module procedure scalar_count, vector_count
end interface
interface operator(.wide.)
module procedure narrow, wide
end interface
contains
pure elemental integer function scalar_count(x) result(y)
integer,intent(in)::x
y=100+x
end function
pure integer function vector_count(x) result(y)
integer,intent(in)::x(:)
y=size(x)
end function
pure integer function narrow(x) result(y)
integer,intent(in)::x
y=4
end function
pure integer function wide(x) result(y)
integer(kind=8),intent(in)::x
y=8
end function
end module
program main
use ops
implicit none
print *, .count. [1,2,3], .count. 4, .wide. 1, .wide. 1_8
end program
