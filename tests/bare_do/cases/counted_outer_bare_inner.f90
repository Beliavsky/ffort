program p
implicit none
integer::i,j,n
n=0
outer: do i=1,3
do
n=n+1
cycle outer
end do
end do outer
print *,n,i
end program
