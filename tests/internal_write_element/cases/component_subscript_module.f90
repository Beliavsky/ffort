module m
implicit none
type::box
integer::n=2
end type
end module
program main
use m
implicit none
type(box)::x
character(2)::a(2)
write(a(x%n),'(i2.2)')7
print '(a)',a(2)
end program
