program probe
  implicit none
  integer :: i, s
  s=0
  do i=1,8,3
   s=s+i
  end do
  print *, s, i
end program probe
