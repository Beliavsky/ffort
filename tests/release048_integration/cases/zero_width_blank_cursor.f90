program p
implicit none
character(:),allocatable::s,c(:)
s='ABCD'
c=[s]
print '(a,t2,z0.0,a)',c,iand(1,2),'!'
end program
