program p
implicit none
character(100)::s

s="OLD"
write(s,'("colon:",i0:,"skip:")')
print "(a)",trim(s)
end program
