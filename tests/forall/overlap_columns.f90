program p
implicit none
integer::a(2,4),i
a=reshape([1,2,3,4,5,6,7,8],[2,4])
forall(i=1:4) a(:,i)=a(:,5-i)
print *,a
end program
