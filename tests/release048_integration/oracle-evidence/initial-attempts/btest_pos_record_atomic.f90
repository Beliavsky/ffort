program p
implicit none
integer::p
character(:),allocatable::s,c(:)
s='DROP'
c=[s]
print '(a)','SAFE'
p=32
print '(a,l1)',c,btest(1,p)
end program
