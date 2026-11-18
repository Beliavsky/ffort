program p
implicit none
integer::a(3,2),idx(3),b(2,2)
a=reshape([1,2,3,4,5,6],[3,2])
idx=[3,2,1]
b=a(pack(idx,idx/=2),:)
print *,b
end program
