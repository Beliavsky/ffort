program p
implicit none
character(100)::s

s="OLD"
write(s,'(i0,:,3x,"T")')
print "(a)",trim(s)
end program
