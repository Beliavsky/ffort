program p
implicit none
integer::a(3,3,3),b(3,3,3),idx(3),i
b=1
idx=[3,1,2]
forall(i=1:3)a(i,1,1)=sum(b(:,idx,:))
end program
