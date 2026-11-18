program p
integer,allocatable::a(:,:,:),b(:,:,:)
allocate(a(-2:-1,4:4,7:8)); allocate(b(3:4,-1:-1,9:10))
a=2; b=7
a=b
print *,lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,lbound(a,3)))
deallocate(b)
allocate(b(3:3,-1:0,9:11)); b=4
a=b
print *,size(a,1),size(a,2),size(a,3),lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,lbound(a,3)))
end program
