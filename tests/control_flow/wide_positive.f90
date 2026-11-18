program control
implicit none
integer(8) :: i,n
n=0
do i=2147483648_8,2147483652_8,2_8
 n=n+1
 print *,i
end do
print *,n,i,kind(i)
end program control
