program p
implicit none
integer::a(3,3,3),idx(1)
integer,allocatable::b(:,:,:)
idx=[2]
b=a(:,:,idx)
end program
