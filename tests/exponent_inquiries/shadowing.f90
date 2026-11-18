module shadows
contains
integer function minexponent(x)
integer,intent(in)::x
minexponent=x+7
end function
end module
program main
use shadows
implicit none
integer::maxexponent(2)=[9,11]
print *,minexponent(3),maxexponent(2)
end program
