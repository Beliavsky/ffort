module z
type::box
integer::x
end type
end module
program p
use z
type(box)::b
print *,kind(b)
end program
