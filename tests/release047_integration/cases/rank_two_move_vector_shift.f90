program p
implicit none
integer::u
real,allocatable::a(:,:),b(:,:)
real::c(2,3)
u=27
allocate(a(2,3))
read(u,*)a
call move_alloc(a,b)
c=eoshift(b,[1,-1],boundary=[0.,9.],dim=2)
print '(6f5.1)',c
print '(f5.1)',norm2(c(:,1))
end program
