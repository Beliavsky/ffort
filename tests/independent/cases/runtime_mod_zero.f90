program probe
  implicit none
  integer :: x, y
  x=3
  y=0
  x=mod(x,y)
  print *, x
end program probe
