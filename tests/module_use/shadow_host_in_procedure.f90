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
private
public::probe
contains
integer function probe(ival) result(y)
integer,intent(in)::ival
y=ival+1
end function
end module
program main
use second,only:probe
implicit none
print *,probe(20)
end program
