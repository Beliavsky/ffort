program p

implicit none
integer(8),allocatable::a(:,:,:)
integer::idx(2)
character(3)::s(1)
write(s(1),'(i0)')kind(shiftr(a(:,idx,:),0))
print '(a)','['//s(1)//']' 
end program
