program p
implicit none
integer::a(3,3,3),idx(2)
idx=[3,1]
a(idx,:,:)=1
end program
