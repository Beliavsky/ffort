program p
implicit none
integer::a(3,0,3),idx(1)
integer,allocatable::b(:,:,:)
idx=[4]
b=a(idx,:,:)
end program
