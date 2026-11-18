program p
implicit none
integer(8)::a(3,2),b(2,2),idx(2)
a=reshape([1,2,3,4,5,6],[3,2])
idx=[3,1]
b=a(idx,:)
print *,b
end program
