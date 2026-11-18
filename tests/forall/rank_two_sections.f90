program p
implicit none
integer::a(4,2),i
a=reshape([1,2,3,4,5,6,7,8],[4,2])
forall(i=1:2) a(2*i-1:2*i,:)=a(5-2*i:6-2*i,:)
print *,a
end program
