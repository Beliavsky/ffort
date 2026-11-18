program p
implicit none
integer,save :: a=4,b(2)=[2,3],c(2,2)=reshape([1,2,3,4],[2,2])
a=a+1
b=b+a
c=c+a
print *, a,b,c
end program
