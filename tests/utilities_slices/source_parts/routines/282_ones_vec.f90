pure function ones_vec(n) result(xx)
integer, intent(in) :: n
real(kind=dp)       :: xx(n)
xx = 1.0_dp
end function ones_vec
!
