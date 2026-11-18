program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
integer::i
do i=1,1
write(s,"(i2.2)")n
end do
end function
end program
