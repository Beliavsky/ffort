program control
implicit none
integer(8) :: i
i=9
do i=3_8,1_8
 print *,99
end do
print *,i
do i=-3_8,1_8,-1_8
 print *,98
end do
print *,i
end program control
