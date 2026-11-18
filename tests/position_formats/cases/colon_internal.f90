program p
implicit none
character(16)::s
write(s,'(a,t2,a,:,tr5,"tail")') 'abc','X'
print '(a)',s
end program
