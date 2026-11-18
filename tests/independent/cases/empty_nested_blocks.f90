program probe
  implicit none
  integer :: i, x
  x=7
  if (.true.) then
   do i=1,2
    if (.false.) then
    else
    end if
   end do
  else
  end if
  print *, x,i
end program probe
