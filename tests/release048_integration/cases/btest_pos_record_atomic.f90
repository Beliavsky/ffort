program p
implicit none
integer::pos
character(:),allocatable::s,c(:)
s='DROP'
c=[s]
print '(a)','SAFE'
pos=32
print '(a,l1)',c,btest(1,pos)
end program
