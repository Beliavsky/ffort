program main
implicit none
integer::i,j
integer::a(0)
print *, ((a,j=1,32767),i=1,2)
print *,i,j
end program
