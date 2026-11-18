program p
implicit none
integer,allocatable::a(:,:,:)
integer::idx(2),i
allocate(a(3,3,3))
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
a=a(:,idx,:)
if(any(shape(a)/=[3,2,3]))error stop 1
if(any(a/=reshape([7,8,9,1,2,3,16,17,18,10,11,12,25,26,27,19,20,21],[3,2,3])))error stop 2
print '(i0)',1
end program
