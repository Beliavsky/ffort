program main
implicit none
integer :: i, isum
integer, parameter :: imax = 10
isum = 0
do i=1,imax
   isum = isum + i
end do
print*,isum
end program main
