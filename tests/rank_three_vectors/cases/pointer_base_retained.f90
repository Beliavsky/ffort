program p
implicit none
integer,target::storage(3,3,3)
integer,pointer::a(:,:,:)
integer::idx(2)
storage=1
a=>storage
idx=[3,1]
print *,sum(a(:,idx,:))
end program
