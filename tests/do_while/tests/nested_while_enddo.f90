implicit none
integer::i,j,n
i=0
n=0
do while(i<2)
i=i+1
j=0
do while(j<3)
j=j+1
n=n+1
enddo
enddo
print "(i0)",n
end
