program p
implicit none
character(100)::s
integer::a(5)
s="OLD"
a=7
write(s,'("P",*(i0:3x))')a
print "(a)",trim(s)
end program
