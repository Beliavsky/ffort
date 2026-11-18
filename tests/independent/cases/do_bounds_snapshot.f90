program probe
  implicit none
  integer :: i, s, upper, stride
  s=0
  upper=5
  stride=2
  do i=1,upper,stride
   s=s+i
   upper=1
   stride=1
  end do
  print *, s, i, upper, stride
end program probe
