program p
implicit none
integer::a(-2:0,4:5),b(2,2),idx(2)
a=reshape([1,2,3,4,5,6],[3,2])
idx=[0,-2]
b=a(idx,:)
print *,b
end program
