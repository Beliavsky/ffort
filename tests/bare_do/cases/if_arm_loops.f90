program p
implicit none
integer::i,j,n
n=0
if(.true.) then
do
n=n+1
exit
end do
else if(.false.) then
do
n=99
exit
end do
else
do
n=88
exit
end do
end if
print *,n
end program
