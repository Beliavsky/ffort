program probe
  implicit none
  integer :: i, s
  s=0
  do i=1,2
   s=s+i
  end do
  do i=2,1,-1
   s=s+i
  end do
  print *, s, i
end program probe
