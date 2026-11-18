program p
implicit none
real(8),allocatable::a(:,:)
integer::idx(2)
print *,kind(a(idx,:))
end program
