program p
implicit none
character(16)::s
write(s,'(a,tl65536,a)') 'abc','Z'
print '(a)',s
end program
