program p
implicit none
integer::i,j,n
n=0
outer: do
do i=1,3
do
n=n+1
exit outer
end do
end do
end do outer
i=10
print *,n,i
end program
