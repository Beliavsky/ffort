program p
implicit none
integer::a(3,3,3),idx(1)
integer,allocatable::b(:,:,:)
a(:,:,2)=9
idx=[2]
b=a(:,:,idx)
if(any(b/=9))error stop 1
print '(i0)',1
end program
