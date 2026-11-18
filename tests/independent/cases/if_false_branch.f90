program probe
  implicit none
  integer :: x, y
  x=0
  y=3
  if (x>2) then
   y=10
  else
   y=y+1
  end if
  print *, y
end program probe
