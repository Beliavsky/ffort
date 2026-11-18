program p
implicit none
integer::a(3,2),i
a=reshape([1,2,3,4,5,6],[3,2])
forall(i=1:3) a(i,:)=a(4-i,:)
print *,a
end program
