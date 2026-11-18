program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s

write(*,"(i2.2)")n
s="07"
end function
end program
