program p
implicit none
integer::a(0,3,3),idx(1)
integer,allocatable::b(:,:,:)
b=a(:,:,idx)
end program
