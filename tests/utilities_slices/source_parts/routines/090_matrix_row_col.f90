function matrix_row_col(nrow,ncol) result(xmat)
integer, intent(in) :: nrow,ncol
real(kind=dp) :: xmat(nrow,ncol)
xmat = 0.0_dp
end function matrix_row_col
!
