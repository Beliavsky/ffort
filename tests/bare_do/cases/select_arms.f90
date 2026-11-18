program p
implicit none
integer::i,j,n
n=0
do
n=n+1
select case(n)
case(1)
cycle
case(2)
do
j=9
exit
end do
case default
exit
end select
end do
print *,n,j
end program
