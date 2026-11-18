program p
implicit none
integer::a(3,3),i,j
a=reshape([1,2,3,4,5,6,7,8,9],[3,3])
forall(i=1:3,j=1:3) a(i,j)=a(j,i)
print *,a
end program
