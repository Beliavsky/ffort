program control
implicit none
integer(8) :: i,n
n=0
do i=9223372036854775804_8,9223372036854775806_8
 n=n+1
end do
print *,n,i
end program control
