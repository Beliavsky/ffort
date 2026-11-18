program p
implicit none
integer,allocatable::a(:,:,:)
integer::idx(2),i
allocate(a(3,3,3))
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
a=a(:,:,idx)
if(any(shape(a)/=[3,3,2]))error stop 1
if(any(a/=reshape([19,20,21,22,23,24,25,26,27,1,2,3,4,5,6,7,8,9],[3,3,2])))error stop 2
print '(i0)',1
end program
