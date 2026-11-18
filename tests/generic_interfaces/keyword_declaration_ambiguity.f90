module operations
implicit none
interface choose
module procedure f,g
end interface
contains
integer function f(i,r) result(y)
integer,intent(in)::i
real,intent(in)::r
y=i+int(r)
end function
integer function g(r,i) result(y)
real,intent(in)::r
integer,intent(in)::i
y=i+int(r)
end function
end module
program main
use operations
implicit none
end program
