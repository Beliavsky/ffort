program p
implicit none
integer::a(3,3,0),idx(2)
integer,allocatable::b(:,:,:)
idx=[3,1]
b=a(:,idx,:)
if(size(b)/=0)error stop 1
print '(i0)',1
end program
