program p
implicit none
character(100)::s
integer::a(1)
s="OLD"
a=7
write(s,'(2(i0,:,";"))')a
print "(a)",trim(s)
end program
