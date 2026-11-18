subroutine unique_real(xx,ipos,nuniq,tol)
! return in ipos(1:nuniq) the positions of the unique elements of xx(:)
real(kind=dp), intent(in)  :: xx(:)
integer      , intent(out) :: ipos(:) ! positions of unique integers in xx
integer      , intent(out) :: nuniq   ! # of unique integers in xx
real(kind=dp), intent(in), optional :: tol ! error tolerance
integer                    :: i,n
n = size(xx)
ipos = 0
if (size(ipos) /= n) then
   write (*,*) mod_str//"unique_int, size(xx), size(ipos) =",n,size(ipos)," should be equal, stopPinG"
   stop
end if
if (n == 0) then
   nuniq = 0
   return
end if
ipos(1) = 1
nuniq   = 1
do i=2,n
   if (all(abs(xx(i) - xx(ipos(:nuniq))) > default(1.0e-10_dp,tol))) then
!   if (all(abs(xx(i) - xx(ipos(:nuniq)) > 1.0d-10 )))) then
      nuniq = nuniq + 1
      ipos(nuniq) = i
   end if
end do
end subroutine unique_real
!
