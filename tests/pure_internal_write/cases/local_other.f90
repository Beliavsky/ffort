program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
character(2)::tmp
write(tmp,"(i2.2)")n
s=tmp
end function
end program
