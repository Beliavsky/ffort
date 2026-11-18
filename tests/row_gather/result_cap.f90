program p
implicit none
integer::a(1,1000),idx(1001)
integer,allocatable::b(:,:)
a=1
idx=1
b=a(idx,:)
end program
