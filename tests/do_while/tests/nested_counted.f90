implicit none
integer::i,n,j
n=0
do j=1,3
i=0
do while(i<j)
i=i+1
n=n+1
end do
end do
print "(i0)",n
end
