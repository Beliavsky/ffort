program p
implicit none
character(2)::a(3,3,3)
integer::idx(2)
idx=[3,1]
print *,size(a(idx,:,:))
end program
