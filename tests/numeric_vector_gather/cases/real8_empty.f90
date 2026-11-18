program p
implicit none
real(8)::a(4),b(0)
integer::idx(0)
b=a(idx)
if(size(b)/=0)error stop 1
print '(i0)',1
end program
