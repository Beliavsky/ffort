pure function last_pos_le_real(xvec,xval) result(ipos)
! return the position of the last element of xvec(:) that is <= xval,
! 0 if none are >=
real(kind=dp), intent(in) :: xvec(:),xval
integer                   :: ipos
integer                   :: i,n
n    = size(xvec)
ipos = 0
do i=n,1,-1
   if (xvec(i) <= xval) then
      ipos = i
      exit
   end if
end do
end function last_pos_le_real
!
