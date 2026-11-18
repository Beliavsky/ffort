module types
implicit none
integer::n
type::dt
integer::a=n
end type
end module
program p
use types
implicit none
type(dt)::x

end program
