program p
implicit none
character(:),allocatable::s,f(:)
character(12)::buf
s='(z8.8)'
f=[s,s]
write(buf,f(2))not(0)
print '(a,a,a)','[',buf,']'
end program
