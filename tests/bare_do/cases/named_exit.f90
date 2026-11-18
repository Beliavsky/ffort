program p
implicit none
integer::i,j,n
n=0
outer: do
n=n+1
do
exit outer
end do
end do outer
print *,n
end program
