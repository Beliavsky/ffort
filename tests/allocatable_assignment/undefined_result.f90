program probe
implicit none
integer, allocatable :: a(:)
a=make()
contains
function make() result(z)
integer,allocatable :: z(:)
allocate(z(2))
z(1)=1
end function
end program
