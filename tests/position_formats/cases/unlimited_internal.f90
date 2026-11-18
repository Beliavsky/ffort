program p
implicit none
character(16)::s
write(s,'(*(a,tl1,a))') 'abc','X','def','Y'
print '(a)',s
end program
