module first
implicit none
integer,parameter::ival=7,k=8
contains
integer function twice(x) result(y)
integer,intent(in)::x
y=2*x
end function
end module
module second
use first,only:
implicit none
integer,parameter::value=3
end module
program main
use second
implicit none
print *,value
end program
