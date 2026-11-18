program p
implicit none
character(100)::s

s="OLD"
write(s,'("P",*(i0:3x))')
print "(a)",trim(s)
end program
