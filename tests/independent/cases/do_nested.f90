program probe
  implicit none
  integer :: i, j, s
  s=0
  do i=1,2
   do j=1,3
    s=s+10*i+j
   end do
  end do
  print *, s, i, j
end program probe
