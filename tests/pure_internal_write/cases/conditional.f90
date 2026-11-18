program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s

if(n>0)then
write(s,"(i2.2)")n
else
s="00"
end if
end function
end program
