program p
implicit none
integer::a(3,2),b(2,2)
integer(8)::idx(2)
a=reshape([1,2,3,4,5,6],[3,2])
idx=[3_8,1_8]
b=a(idx,:)
print *,b
end program
