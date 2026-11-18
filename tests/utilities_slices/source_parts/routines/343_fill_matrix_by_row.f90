subroutine fill_matrix_by_row(good,xmat)
! for each row of a matrix, fill positions with data from earlier positions if necessary
logical      , intent(in)     :: good(:,:) ! (n1,n2)
real(kind=dp), intent(in out) :: xmat(:,:) ! (n1,n2)
integer :: i,j,n1,n2
real(kind=dp) :: base
n1 = size(good,1)
n2 = size(good,2)
if (size(xmat,1) /= n1 .or. size(xmat,2) /= n2) then
   write (*,*) "in fill_matrix_by_row, shape(good)=",shape(good)," shape(xmat)=",shape(xmat), &
               " must be equal, STOPPING"
   stop
end if
if (n2 < 2) return
do i=1,n1
   base = xmat(i,1)
   do j=2,n2
      if (good(i,j)) then
         base = xmat(i,j)
      else
         xmat(i,j) = base
      end if
   end do
end do
end subroutine fill_matrix_by_row
!
