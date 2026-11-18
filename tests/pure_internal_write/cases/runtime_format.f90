program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
character(8)::fmt
fmt="(i2.2)"
write(s,fmt)n
end function
end program
