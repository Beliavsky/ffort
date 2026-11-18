subroutine assert_int_range(msg,var,i,imin,imax)
! assert that imin <= i <= imax
character (len=*), intent(in) :: msg,var
integer          , intent(in) :: i,imin,imax
logical, parameter            :: debug = .false. ! .true.
if (debug) print*,"in assert_int_range, i, imin, imax =",i,imin,imax
if (i < imin .or. i > imax) then
   write (*,"(a,a,i0,a,i0,' <= ',a,' <= ',i0,' , STOPPING')") msg,var // " = ",i," , need ",imin,var,imax
   stop
end if
end subroutine assert_int_range
!
