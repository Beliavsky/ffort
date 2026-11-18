implicit none
integer :: i
i = 0
do while (i**2 < 10)
   print*,i,i**2
   i = i + 1
end do
end
