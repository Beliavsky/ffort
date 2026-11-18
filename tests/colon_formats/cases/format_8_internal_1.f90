program p
implicit none
character(100)::s
integer::a(1)
s="OLD"
a=7
write(s,'("P",2(i0:,";"),:"END")')a
print "(a)",trim(s)
end program
