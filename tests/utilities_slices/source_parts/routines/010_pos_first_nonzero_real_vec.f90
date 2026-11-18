function pos_first_nonzero_real_vec(xx) result(ipos)
real(kind=dp), intent(in) :: xx(:)
integer                   :: ipos
integer                   :: i
ipos = 0
do i=1,size(xx)
   if (xx(i) /= 0.0_dp) then
      ipos = i
      exit
   end if
end do
end function pos_first_nonzero_real_vec
!
