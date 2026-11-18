pure function first_pos_ge_real(xvec,xval) result(ipos)
! return the position of the first element of xvec(:) that is >= xval,
! n+1 if none are >= xval
real(kind=dp), intent(in) :: xvec(:),xval
integer                   :: ipos
integer                   :: i,n
n    = size(xvec)
ipos = n+1
do i=1,n
   if (xvec(i) >= xval) then
      ipos = i
      exit
   end if
end do
end function first_pos_ge_real
!
