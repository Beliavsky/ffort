program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
character(:),allocatable::t
t="00"
write(t,"(i2.2)")n
s=t
end function
end program
