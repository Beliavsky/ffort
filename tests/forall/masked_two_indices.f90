program p
implicit none
integer::a(-1:1,2:4),i,j
a=-9
i=70
j=80
forall(i=-1:1,j=4:2:-1,i+j>2) a(i,j)=10*j+i
print *,a,i,j
end program
