program p
implicit none
integer::a(0,3,3),idx(1)
integer,allocatable::b(:,:,:)
idx=[4]
b=a(:,:,idx)
end program
