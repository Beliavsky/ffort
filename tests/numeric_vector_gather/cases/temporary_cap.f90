program p
implicit none
integer::a(1)
integer,allocatable::idx(:),b(:)
a=1
allocate(idx(500001))
idx=1
b=a(idx)
end program
