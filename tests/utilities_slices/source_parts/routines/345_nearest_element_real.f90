function nearest_element_real(xx,xvec) result(yy)
! return in yy the value of the element of xvec(:) that is closest to xx (in absolute deviation terms)
real(kind=dp), intent(in) :: xx
real(kind=dp), intent(in) :: xvec(:)
real(kind=dp)             :: yy
integer                   :: i,n
real(kind=dp)             :: dist,min_dist
n = size(xvec)
if (n < 1) return
yy = xvec(1)
min_dist = abs(xx-xvec(1))
do i=2,n
   dist = abs(xx-xvec(i))
   if (dist < min_dist) then
      min_dist = dist
      yy = xvec(i)
   end if
end do
end function nearest_element_real
!
! function first_repeat(ivec) result(tf)
! integer, intent(in) :: ivec(:)
! logical             :: tf(size(ivec))
! integer             :: i
! do i=1,size(ivec)-1
!    tf(i) = (ivec(i) == ivec(i+1))
! end do
! end function first_repeats
!
