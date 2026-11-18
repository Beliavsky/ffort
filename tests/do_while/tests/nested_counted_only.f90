implicit none
integer::i,j,n
n=0
do i=1,2
do j=1,3
n=n+1
end do
end do
print "(i0)",n
end
