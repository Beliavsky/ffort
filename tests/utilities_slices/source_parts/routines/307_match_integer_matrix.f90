subroutine match_integer_matrix(xnames,ynames,idir,jdir,outu)
character (len=*), intent(in)     :: xnames(:),ynames(:)
integer          , intent(in)     :: idir(:,:)
integer          , intent(in out) :: jdir(:,:)
integer          , intent(in), optional :: outu
integer                           :: i,j,ii,jj,nx,ny,outu_
outu_ = default(istdout,outu)
nx = size(xnames)
ny = size(ynames)
do i=1,nx
   ii = match_string_scalar(xnames(i),ynames)
   if (ii == 0) then
      write (outu_,*) "WARNING: no match for symbol ",trim(xnames(i))," in ", &
                  (trim(ynames(j)) // " ",j=1,ny)
      cycle
   end if
   do j=1,nx
      jj = match_string_scalar(xnames(j),ynames)
      if (jj > 0) jdir(i,j) = idir(ii,jj)
   end do
end do
end subroutine match_integer_matrix
!
