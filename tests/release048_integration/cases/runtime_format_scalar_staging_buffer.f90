program p
implicit none
character(:),allocatable::s,f(:)
character(12)::buf
character(16)::fmt
s='(z8.8)'
f=[s,s]
fmt=f(2)
write(buf,fmt)not(0)
print '(a,a,a)','[',buf,']'
end program
