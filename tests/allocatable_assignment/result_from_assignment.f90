program probe
implicit none
integer, allocatable :: a(:)
a=make()
print *,lbound(a,1),ubound(a,1),a
print *,sum(make())
contains
function make() result(z)
integer,allocatable :: z(:)
z=[1,2,3]
end function
end program
