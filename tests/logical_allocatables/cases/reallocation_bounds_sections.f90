program p
logical,allocatable::a(:,:,:),b(:,:,:)
allocate(a(-1:0,4:4,7:8));a=.false.
allocate(b(2:3,5:5,9:10));b=.true.
a=b
print *,lbound(a,1),lbound(a,2),lbound(a,3),a
b(3,5,10)=.false.
a(:,:,7)=b(:,:,10)
print *,a
deallocate(b);allocate(b(3:3,-1:0,9:11));b=.false.
a=b
print *,size(a,1),size(a,2),size(a,3),lbound(a,1),lbound(a,2),lbound(a,3),a
end program
