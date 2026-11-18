module second
use first
implicit none
end module
module first
implicit none
integer,parameter::ival=7,k=8
contains
integer function twice(x) result(y)
integer,intent(in)::x
y=2*x
end function
end module
program main
end program
