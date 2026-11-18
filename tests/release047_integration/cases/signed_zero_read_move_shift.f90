program p
implicit none
integer::u
real(8),allocatable::a(:),b(:)
real(8)::c(2)
u=27
allocate(a(2))
read(u,*)a
call move_alloc(a,b)
c=eoshift(b,1,boundary=-0d0)
print '(2es25.17)',c
end program
