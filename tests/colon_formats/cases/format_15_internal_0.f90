program p
implicit none
character(100)::s

s="OLD"
write(s,'(*(i0:,""))')
print "(a)",trim(s)
end program
