pure function pow_norm(n,pow) result(wgt)
! return a vector containing a power of the first n integers, normalized to sum to 1
integer      , intent(in) :: n
real(kind=dp), intent(in) :: pow
real(kind=dp)             :: wgt(n)
integer                   :: i
if (n < 1) return
forall (i=1:n) wgt(i) = i**pow
wgt = wgt/sum(wgt)
end function pow_norm
!
