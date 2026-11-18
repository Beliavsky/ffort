program p
implicit none
integer a(-1:1),b(2,2),c(2,1,2)
a=[1,2,3]
b=reshape([4,5,6,7],[2,2])
c(:,1,1)=[8,9]
c(:,1,2)=[10,11]
print *,a,b,c
end program
