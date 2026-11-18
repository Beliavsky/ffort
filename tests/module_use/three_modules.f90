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
use first,only:ival,k,twice
implicit none
private
public::value,probe
integer,parameter::value=ival+1
contains
integer function probe(x) result(y)
integer,intent(in)::x
y=twice(x)+value
end function
end module
module third
use second,only:value,probe
implicit none
private
public::answer,run
integer,parameter::answer=value+1
contains
integer function run(x) result(y)
integer,intent(in)::x
y=probe(x)+answer
end function
end module
program main
use third,only:answer,run
implicit none
print *,answer,run(5)
end program
