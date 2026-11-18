program probe
  implicit none
  integer :: x, y
  x=3
  if (x>2) then
   y=10
  else
   y=20
  end if
  print *, y
end program probe
