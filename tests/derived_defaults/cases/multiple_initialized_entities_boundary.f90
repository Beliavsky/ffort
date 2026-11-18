module types
implicit none
type::dt
integer::a=1,b=2
end type
end module
program p
use types
implicit none
type(dt)::x

end program
