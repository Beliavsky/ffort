program p
implicit none
integer,allocatable::a(:,:)
integer::idx(0)
allocate(a(3,2))
a=1
a=a(idx,:)
print *,shape(a)
end program
