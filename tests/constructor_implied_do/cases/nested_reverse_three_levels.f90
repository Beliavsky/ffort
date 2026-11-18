program main
implicit none
integer::i,j,k,a(10)
i=77
j=88
k=99
a=[(((100*i+10*j+k,k=j,1,-1),j=i,1,-1),i=1,3)]
print *,a,i,j,k
end program
