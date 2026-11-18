module types
implicit none
type::dt
real::a=huge(1.0)*2.0
end type
end module
program p
use types
implicit none
type(dt)::x

end program
