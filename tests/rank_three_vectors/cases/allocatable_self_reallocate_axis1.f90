program p
implicit none
integer,allocatable::a(:,:,:)
integer::idx(2),i
allocate(a(3,3,3))
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
a=a(idx,:,:)
if(any(shape(a)/=[2,3,3]))error stop 1
if(any(a/=reshape([3,1,6,4,9,7,12,10,15,13,18,16,21,19,24,22,27,25],[2,3,3])))error stop 2
print '(i0)',1
end program
