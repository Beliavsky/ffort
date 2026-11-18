program main
implicit none
integer::i
integer::a(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
print *, (a(:,i),i=3,1,-1)
end program
