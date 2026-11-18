program p
implicit none
integer::a(3,2),idx(2),b(2,2)
a=reshape([1,2,3,4,5,6],[3,2])
idx=[3,1]
b=a(idx,:)
print *,b
idx=[2,2]
a=a+10
b=a(idx,:)
print *,b
end program
