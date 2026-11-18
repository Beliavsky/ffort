program p
implicit none
integer::a(3)
character(:),allocatable::s,c(:)
s='go'
c=[s]
print '(a)',c
a=ior([1,2,3],8)
print '(2(z4.2))',a
end program
