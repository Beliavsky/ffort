program p
implicit none
print "(a)",mark(7)
contains
subroutine unrelated()
character(2)::u
end subroutine
pure function mark(n) result(s)
integer,intent(in)::n
integer::u
character(2)::s
u=6
write(u,"(i2.2)")n
s="07"
end function
end program
