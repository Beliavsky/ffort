program probe
  implicit none
  integer :: i
  do i=1,3
   if (.false.) then
    i=2
   end if
  end do
end program probe
