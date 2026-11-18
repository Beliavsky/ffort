program p
implicit none
character(100)::s

s="OLD"
write(s,'("P",2(i0:,";"),:"END")')
print "(a)",trim(s)
end program
