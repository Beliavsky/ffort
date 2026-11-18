subroutine assert_int_vec_range(msg,var,ivec,imin,imax)
! assert that all(imin <= ivec(:) <= imax)
character (len=*), intent(in) :: msg,var
integer          , intent(in) :: ivec(:),imin,imax
logical, parameter            :: debug = .false. ! .true.
integer                       :: k,n
if (debug) print*,"in assert_int_range, ivec, imin, imax =",ivec,imin,imax
n = size(ivec)
do k=1,n
   if (ivec(k) < imin .or. ivec(k) > imax) then
      write (*,"(a,a,i0,a,i0,a,i0,' <= ',a,' <= ',i0)") msg,"element ",k," of " // var // " equals ", &
      ivec(k)," , need all ",imin,var,imax
      stop
   end if
end do
end subroutine assert_int_vec_range
!
