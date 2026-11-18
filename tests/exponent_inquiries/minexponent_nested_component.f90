module types
type::item
real::x
end type
end module
program main
use types
implicit none
type(item)::v
print *,minexponent(sqrt(v%x))
end program
