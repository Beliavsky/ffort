program p
implicit none
integer::a(3,3,3),idx(0),b(3,3,0)
b=a(:,:,idx)
if(size(b)/=0.or.any(shape(b)/=[3,3,0]))error stop 1
print '(i0)',1
end program
