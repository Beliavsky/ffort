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
use first,only:ival
implicit none
end module
program main
use second,only:ival
implicit none
print *,ival
end program
