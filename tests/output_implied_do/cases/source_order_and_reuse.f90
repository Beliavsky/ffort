program main
implicit none
integer::i,j
i=20
j=30
print *,i,(i,i=1,2),i,(i,i=4,5),i,(j,j=2,1,-1),j
end program
