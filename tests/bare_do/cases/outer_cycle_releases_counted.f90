program p
implicit none
integer::i,j,n
n=0
outer: do
n=n+1
if(n==4) exit
do i=1,9
cycle outer
end do
end do outer
i=20
print *,n,i
end program
