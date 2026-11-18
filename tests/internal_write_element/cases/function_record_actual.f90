program main
implicit none
type::box
integer::n=7
end type
type(box)::x
character(2)::a(1)
write(a(1),'(i2.2)')value(x)
print '(a)',a
contains
integer function value(b)
type(box),intent(in)::b
value=b%n
end function
end program
