program p
implicit none
integer::i,j,n
n=0
do
do i=1,2
n=n+i
end do
exit
end do
print *,n,i
end program
