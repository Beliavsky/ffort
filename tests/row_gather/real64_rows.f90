program p
implicit none
real(8)::a(3,2),b(2,2)
integer::idx(2)
a=reshape([1,2,3,4,5,6],[3,2])
idx=[3,1]
b=a(idx,:)
print *,int(b)
end program
