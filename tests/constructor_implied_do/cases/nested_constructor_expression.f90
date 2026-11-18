program main
implicit none
integer::i,j,a(6)
i=77
j=88
a=[([(10*i+j,j=1,2)],i=1,3)]
print *,a,i,j
end program
