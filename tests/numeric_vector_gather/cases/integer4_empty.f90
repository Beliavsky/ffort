program p
implicit none
integer(4)::a(4),b(0)
integer::idx(0)
b=a(idx)
if(size(b)/=0)error stop 1
print '(i0)',1
end program
