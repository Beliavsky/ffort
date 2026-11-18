module types
implicit none
type::dt
integer::a=2147483647+1
end type
end module
program p
use types
implicit none
type(dt)::x

end program
