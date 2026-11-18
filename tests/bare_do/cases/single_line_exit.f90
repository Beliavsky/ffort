program p
implicit none
integer::i,j,n
n=0
do
n=n+1
if(n==7) exit
end do
print *,n
end program
