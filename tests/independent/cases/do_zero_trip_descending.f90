program probe
  implicit none
  integer :: i, s
  s=7
  do i=1,5,-1
   s=0
  end do
  print *, s, i
end program probe
