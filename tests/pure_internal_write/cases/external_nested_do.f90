program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
integer::i
do i=1,1
write(*,"(i2.2)")n
end do
s="07"
end function
end program
