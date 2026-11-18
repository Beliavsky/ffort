module first
implicit none
integer,parameter::ival=7,k=8
contains
integer function twice(x) result(y)
integer,intent(in)::x
y=2*x
end function
end module
module other
implicit none
integer,parameter::ival=100
end module
module second
use first,only:ival
implicit none
private
public::value
integer,parameter::value=ival
end module
program main
use other,only:ival
use second,only:value
implicit none
print *,ival,value
end program
