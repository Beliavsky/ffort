program main
implicit none
integer::i,j,k
print *, ((10*i+j,j=1,i),i=1,4)
print *,i,j
print *, (((100*i+10*j+k,k=j,1,-1),j=i,1,-1),i=1,3)
print *,i,j,k
end program
