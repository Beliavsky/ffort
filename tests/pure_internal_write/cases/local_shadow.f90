module m
integer::s
end module
program p
use m
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
write(s,"(i2.2)")n
end function
end program
