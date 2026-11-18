module first
implicit none
private
public::double_it
interface double_it
module procedure twice
end interface
contains
integer function twice(x) result(y)
integer,intent(in)::x
y=2*x
end function
end module
module second
use first,only:double_it
implicit none
private
public::probe
contains
integer function probe(x) result(y)
integer,intent(in)::x
y=double_it(x)
end function
end module
program main
use second,only:probe
implicit none
print *,probe(7)
end program
