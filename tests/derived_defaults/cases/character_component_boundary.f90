module types
implicit none
type::dt
character(2)::a='ok'
end type
end module
program p
use types
implicit none
type(dt)::x

end program
