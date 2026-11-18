program probe
  implicit none
  integer :: x
  x=2
  if (.true.) then
   if (x==2) then
    x=9
   else
    x=8
   end if
  else
   x=7
  end if
  print *, x
end program probe
