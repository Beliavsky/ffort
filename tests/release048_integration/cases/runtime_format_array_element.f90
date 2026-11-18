program p
implicit none
character(:),allocatable::s,f(:)
character(12)::out
s='(z8.8)'
f=[s,s]
write(out,f(2))not(0)
print '(a,a,a)','[',out,']'
end program
