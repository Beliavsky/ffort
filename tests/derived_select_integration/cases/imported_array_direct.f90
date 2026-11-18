module m
implicit none
integer(8),parameter::a(1)=[9007199254740993_8]
type::box
integer(8)::v
end type
contains
function identity(z) result(q)
integer(8),intent(in)::z
integer(8)::q
q=z
end function
end module
program p
use m
implicit none
type(box)::x
print '(i0)',a(1)
end program
