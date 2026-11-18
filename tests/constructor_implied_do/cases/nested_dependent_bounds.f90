program main
implicit none
integer::i,j,a(10)
i=77
j=88
a=[((10*i+j,j=1,i),i=1,4)]
print *,a,i,j
end program
