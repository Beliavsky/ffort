program main
implicit none
integer::i,char(3),cshift(3)
char=[10,20,30]
cshift=[1,2,3]
print *, (char(i),cshift(i),i=1,3)
end program
