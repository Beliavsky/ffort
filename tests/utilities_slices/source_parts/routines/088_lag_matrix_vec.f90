function lag_matrix_vec(nlags,xx) result(xmat)
! return a matrix of lagged values of a vector, with the 1st-lagged vector in column 1,
! the 2nd-lagged vector in column 2, etc.
real(kind=dp), intent(in) :: xx(:)  ! vector to be lagged
integer      , intent(in) :: nlags
real(kind=dp)             :: xmat(size(xx)-nlags,nlags)
integer                   :: i,i1,iadd
iadd = size(xx) - nlags - 1
do i=1,nlags
   i1 = 1+nlags-i
   xmat(:,i) = xx(i1:i1+iadd)
end do
end function lag_matrix_vec
!
