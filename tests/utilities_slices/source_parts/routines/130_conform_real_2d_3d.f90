function conform_real_2d_3d(yy,xx,dim) result(tf)
real(kind=dp), intent(in) :: xx(:,:,:),yy(:,:)
logical                   :: tf
integer      , intent(in) :: dim(:)
integer      , parameter  :: rank_x = 2
integer                   :: i
if (size(dim) /= rank_x .or. any(dim > 3) .or. any(dim < 1)) then
   tf = .false.
   return
end if
tf = .true.
do i=1,rank_x
   if (size(xx,dim(i)) /= size(yy,i)) then
      tf = .false.
      exit
   end if
end do
end function conform_real_2d_3d
!
