program p
implicit none
integer::a(2,1,2)
character(:),allocatable::s,c(:)
a(:,1,1)=[1,2]
a(:,1,2)=[3,4]
a=ior(a,8)+bit_size(a)
s='>'
c=[s]
print '(a,4z2.2)',c,a
end program
