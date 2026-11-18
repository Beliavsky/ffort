program p
implicit none
character(:),allocatable::s,c(:)
character(12)::fmt
s='SAFE'
c=[s]
print '(a)',c
fmt='(z2,/)'
print fmt,ior(1,2)
end program
