program main
implicit none
integer::i,j
j=88
print *, ((j,j=3,i),i=1,2)
print *,i,j
end program
