program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s

write(unit=s,fmt="(i2.2)")n
end function
end program
