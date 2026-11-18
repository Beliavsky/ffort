subroutine interpolate_matrix(good,xorig,xx)
! interpolate data using average of data before and after
logical      , intent(in)  :: good(:,:)
real(kind=dp), intent(in)  :: xorig(:,:)
real(kind=dp), intent(out) :: xx(:,:)
integer                    :: icol,ncol,n
ncol = size(xx,2)
n    = size(xx,1)
if (size(good,1) /= n .or. size(good,2) /= ncol .or. size(xorig,1) /= n .or. size(xorig,2) /= ncol) then
   print*,"in interpolate_matrix, shape(good)=",shape(good), &
          " shape(xorig)=",shape(xorig)," shape(xx)=",shape(xx)," should all be equal, STOPPING"
   stop
end if
do icol=1,ncol
   call interpolate_vec(good(:,icol),xorig(:,icol),xx(:,icol))
end do
end subroutine interpolate_matrix
!
