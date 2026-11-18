implicit none
integer::i,n,j
i=0
n=0
do while(i<3)
i=i+1
j=0
do while(j<i)
j=j+1
n=n+1
end do
end do
print "(i0)",n
end
