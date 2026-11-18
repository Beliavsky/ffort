program p
implicit none
character(100)::s
integer::a(1)
s="OLD"
a=7
write(s,'(i0,:,3x,"T")')a
print "(a)",trim(s)
end program
