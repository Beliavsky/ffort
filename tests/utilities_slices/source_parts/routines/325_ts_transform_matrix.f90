function ts_transform_matrix(trans,xx) result(yy)
character (len=*), intent(in) :: trans
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp), allocatable :: yy(:,:)
integer                    :: i,ncol,nobs,ny
character (len=*), parameter :: msg = "in ts_transform_matrix, "
ncol = size(xx,2)
nobs = size(xx,1)
if (trans == str_ratio_diff) then
   ny = max(0,nobs - 1)
   allocate (yy(ny,ncol))
   if (ny == 0) return
   yy = xx(2:,:)/xx(:ny,:) - 1.0_dp
else if (trans == str_diff) then
   ny = max(0,nobs - 1)
   allocate (yy(ny,ncol))
   if (ny == 0) return
   yy = xx(2:,:) - xx(:ny,:)
else if (trans == str_none) then
   call set_alloc(xx,yy)
else
   write (*,*) msg,"trans = '" // trim(trans) // "' is invalid"
   write (*,*) "must be one of", &
               (" '" // trim(str_trans(i)) // "'",i=1,size(str_trans))
   write (*,*) "STOPPING"
   stop
end if
end function ts_transform_matrix
!
