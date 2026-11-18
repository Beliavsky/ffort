program control
implicit none
integer(8) :: i,n
n=0
do i=0_8,-9223372036854775807_8-1_8,-9223372036854775807_8-1_8
 n=n+1
 if(n==2) exit
end do
print *,n,i
end program control
