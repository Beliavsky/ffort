program p
implicit none
integer::a(3,2),idx(0),b(0,2)
b=a(idx,:)
print *,size(b),shape(b)
end program
