program p
implicit none
integer::a(3,0),idx(2),b(2,0)
idx=[3,1]
b=a(idx,:)
print *,shape(b)
end program
