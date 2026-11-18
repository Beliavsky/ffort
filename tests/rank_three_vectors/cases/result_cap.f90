program p
implicit none
integer,allocatable::a(:,:,:),b(:,:,:)
integer::idx(2)
allocate(a(1,600000,1))
a=1
idx=[1,1]
b=a(idx,:,:)
end program
