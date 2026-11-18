function random_logical_vec(n,prob) result(tf)
! return a logical vector with n*prob true elements on average
integer, intent(in) :: n
real(kind=dp), intent(in) :: prob
logical             :: tf(n)
real(kind=dp)       :: xx(n)
call random_number(xx)
tf = xx > (1-prob)
end function random_logical_vec
!
