program p
implicit none
integer::a(2,3),b(2,3)
a=reshape([1,2,3,4,5,6],[2,3]);b=2
print *,dim(a,b),sign(a(:,2:1:-1),-1)
end program
