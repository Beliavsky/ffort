program p
implicit none
character(16)::s
s='UNCHANGED'
write(s,'(z8.8)')-1
print '(a,a,a)','[',s,']'
end program
