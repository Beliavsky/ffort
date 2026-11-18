program p
implicit none
integer::a(3,3,3)
integer(8)::idx(1)
integer,allocatable::b(:,:,:)
a=1
idx=[0_8]
b=a(:,idx,:)
end program
