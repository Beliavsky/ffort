function running_sum(nterms,xx) result(yy)
! return a running sum using nterms values of xx(:) for each element
integer      , intent(in) :: nterms
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx)-nterms+1)
integer                   :: i
if (nterms > 0) then
   do i=1,size(yy)
      yy(i) = sum(xx(i:i+nterms-1))
!      yy(i-nterms+1) = sum(xx(i:i+nterms-1))
   end do
end if
end function running_sum
!
