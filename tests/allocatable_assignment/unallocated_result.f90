program probe
implicit none
integer, allocatable :: a(:)
a=make()
contains
function make() result(z)
integer,allocatable :: z(:)
end function
end program
