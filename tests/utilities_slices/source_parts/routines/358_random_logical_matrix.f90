function random_logical_matrix(nrow,ncol,prob) result(tf)
! return a logical matrix with each element having probability prob of being true
integer, intent(in) :: nrow,ncol
real(kind=dp), intent(in) :: prob
logical             :: tf(nrow,ncol)
real(kind=dp)       :: xx(nrow,ncol)
call random_number(xx)
tf = xx > (1-prob)
end function random_logical_matrix
!
