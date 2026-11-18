module ops
implicit none
interface operator(.same.)
module procedure one,two
end interface
contains
pure integer function one(x) result(y)
integer,intent(in)::x
y=x
end function
pure real function two(z) result(y)
integer,intent(in)::z
y=real(z)
end function
end module
program main
use ops
implicit none
print *,42
end program
