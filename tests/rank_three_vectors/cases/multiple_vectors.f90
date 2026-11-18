program p
implicit none
integer::a(3,3,3),idx(2)
idx=[3,1]
print *,size(a(idx,idx,:))
end program
