program main
implicit none
integer::i,j
i=99
j=99
print *, (i,i=4,1), (j,j=-4,1,-2)
print *,i,j
end program
