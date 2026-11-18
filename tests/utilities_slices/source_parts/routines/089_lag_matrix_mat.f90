function lag_matrix_mat(nlags,xx) result(xmat)
! return a matrix of lagged values of a matrix, with the 1st-lagged vector in column 1,
! the 2nd-lagged vector in column 2, etc.
real(kind=dp), intent(in) :: xx(:,:)  ! matrix to be lagged
integer      , intent(in) :: nlags
real(kind=dp)             :: xmat(size(xx,1)-nlags,nlags*size(xx,2))
integer                   :: i,i1,iadd,j1,ncol
iadd = size(xx,1) - nlags - 1
ncol = size(xx,2)
! print*,"in lag_matrix_mat, iadd, nlags, shape(xx) =",iadd,nlags,shape(xx)," shape(xmat)=",shape(xmat) !! debug
do i=1,nlags
   i1                   = 1+nlags-i
   j1                   = 1 + (i-1)*ncol
   xmat(:,j1:j1+ncol-1) = xx(i1:i1+iadd,:)
end do
end function lag_matrix_mat
!
