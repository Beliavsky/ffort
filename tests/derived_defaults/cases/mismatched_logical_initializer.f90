module types
implicit none
type::dt
logical::a=3
end type
end module
program p
use types
implicit none
type(dt)::x

end program
