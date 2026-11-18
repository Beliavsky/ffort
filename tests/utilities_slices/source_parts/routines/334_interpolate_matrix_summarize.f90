subroutine interpolate_matrix_summarize(good,xorig,xx,outu,labels,fmt_header)
! interpolate data using average of data before and after
logical      , intent(in)  :: good(:,:)
real(kind=dp), intent(in)  :: xorig(:,:)
real(kind=dp), intent(out) :: xx(:,:)
integer, intent(in)        :: outu
character (len=*), intent(in) :: labels(:)
character (len=*), intent(in), optional :: fmt_header
integer                    :: icol,ncol,n,nbad
ncol = size(xx,2)
n    = size(xx,1)
if (size(good,1) /= n .or. size(good,2) /= ncol .or. size(xorig,1) /= n .or. size(xorig,2) /= ncol) then
   print*,"in interpolate_matrix, shape(good)=",shape(good), &
          " shape(xorig)=",shape(xorig)," shape(xx)=",shape(xx)," should all be equal, STOPPING"
   stop
end if
if (present(fmt_header)) then
   if (fmt_header /= "") write (outu,fmt_header)
end if
do icol=1,ncol
   call interpolate_vec(good(:,icol),xorig(:,icol),xx(:,icol))
   nbad = count(.not. good(:,icol))
   write (outu,"(a,',',i0,',',f0.1)") trim(labels(icol)),nbad,nbad*100.0_dp/max(1,n)
end do
end subroutine interpolate_matrix_summarize
!
