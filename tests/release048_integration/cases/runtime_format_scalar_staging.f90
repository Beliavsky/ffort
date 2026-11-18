program p
implicit none
character(:),allocatable::s,f(:)
character(12)::out
character(16)::fmt
s='(z8.8)'
f=[s,s]
fmt=f(2)
write(out,fmt)not(0)
print '(a,a,a)','[',out,']'
end program
