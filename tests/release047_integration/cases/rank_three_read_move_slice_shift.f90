program p
implicit none
integer::u
integer,allocatable::a(:,:,:),b(:,:,:)
integer::c(2)
u=27
allocate(a(-1:0,2:2,4:5))
read(u,*)a
call move_alloc(a,b)
c=eoshift(b(:,2,5),-1,boundary=9)
print '(4i3)',b
print '(2i3)',c
print '(6i3)',lbound(b),ubound(b)
end program
