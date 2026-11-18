module m
implicit none
type::dt
character(3)::s
end type
end module
use m
implicit none
type(dt)::x
print*,kind(x%s)
end
