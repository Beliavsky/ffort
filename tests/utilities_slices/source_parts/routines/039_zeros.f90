pure function zeros(n) result(xvec)
! return a vector of n zeros
integer, intent(in) :: n
real(kind=dp)       :: xvec(n)
xvec = 0.0_dp
end function zeros
!
