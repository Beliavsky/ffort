function matrix_reshape(xvec,ncol) result(xmat)
! convert a vector of N elements to an ncol column matrix
real(kind=dp), intent(in) :: xvec(:)
integer      , intent(in) :: ncol
real(kind=dp)             :: xmat(size(xvec)/ncol,ncol)
integer                   :: icol,nrows
character (len=*), parameter :: msg=mod_str // "matrix_reshape, "
nrows = size(xvec)/ncol
if (ncol < 1 .or. size(xvec) /= nrows*ncol) then
   write (*,*) msg,"size(xvec), ncol, nrows =",size(xvec),ncol,nrows," need ncol > 0, size(xvec) = ncol*nrows"
   stop
end if
forall (icol=1:ncol) xmat(:,icol) = xvec(1+(icol-1)*nrows:icol*nrows)
end function matrix_reshape
!
