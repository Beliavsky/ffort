program p
implicit none
real(8),allocatable::a(:,:,:)
integer::idx(2)
if(kind(a(:,:,idx))/=8)error stop 1
print '(i0)',1
end program
