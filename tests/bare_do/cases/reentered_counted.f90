program p
implicit none
integer::i,j,n
n=0
do j=1,4
do
n=n+1
exit
end do
end do
print *,n,j
end program
