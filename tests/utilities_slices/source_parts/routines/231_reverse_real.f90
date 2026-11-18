function reverse_real(xx) result(xrev)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: xrev(size(xx))
integer                   :: n
n = size(xx)
if (n > 0) xrev = xx(n:1:-1)
end function reverse_real
!
! subroutine match_tf_col_char(xx,xgood,tf_mat)
! character (len=*), intent(in)               :: xx(:)       !
! character (len=*), intent(in)               :: xgood(:)
! logical          , intent(out), allocatable :: tf_mat(:,:)
! end subroutine match_tf_col_char
!
!
