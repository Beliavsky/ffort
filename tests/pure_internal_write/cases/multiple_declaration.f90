program p
implicit none
print "(a)",mark(7)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
character(2)::a,b
write(b,"(i2.2)")n
a=b
s=a
end function
end program
