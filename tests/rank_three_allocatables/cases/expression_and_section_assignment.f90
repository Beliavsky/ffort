program p
integer,allocatable::a(:,:,:),b(:,:,:)
allocate(b(-1:0,4:5,7:9)); b=3
b(0,5,9)=8
a=b+2
print *,lbound(a,1),lbound(a,2),lbound(a,3),sum(a(:,:,1))+sum(a(:,:,2))+sum(a(:,:,3))
a=b(:,:,:)
print *,sum(a(:,:,1))+sum(a(:,:,2))+sum(a(:,:,3))
a(:,:,2)=b(:,:,9)
print *,sum(a(:,:,2)),a(2,2,2)
end program
