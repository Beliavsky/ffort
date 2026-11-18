program p
implicit none
integer::a(3,2),b(2),i
forall(i=1:2) b(i)=sum(a([1,2],:))
end program
