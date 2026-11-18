function random_matrix(nrow,ncol) result(xmat)
integer, intent(in) :: nrow,ncol
real(kind=dp)       :: xmat(nrow,ncol)
call random_number(xmat)
end function random_matrix
!
