program probe
  implicit none
  integer :: x
  x=1
  if (x==0) then
   print *, 0
  else if (x==1) then
   print *, 1
  end if
end program probe
