program p
implicit none
integer(4),allocatable::a(:)
integer::idx(2)
if(kind(a(idx))/=4)error stop 1
print '(i0)',1
end program
