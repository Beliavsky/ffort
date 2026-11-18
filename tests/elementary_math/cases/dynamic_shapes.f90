program p
implicit none
integer,allocatable::a(:),b(:)
allocate(a(3));allocate(b(3))
a=[1,4,7];b=[2,3,8]
print *,dim(a,b),sign(a,-b)
end program
