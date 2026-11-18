program p
implicit none
integer::a(3,3,0),idx(1)
integer,allocatable::b(:,:,:)
b=a(:,idx,:)
end program
