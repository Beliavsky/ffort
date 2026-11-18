pure function repeat_real(n,x) result(xvec)
! return 1-D array of real variables with x repeated n times
integer, intent(in)       :: n
real(kind=dp), intent(in) :: x
real(kind=dp)             :: xvec(n)
integer                   :: j
forall (j=1:n) xvec(j) = x
end function repeat_real
!
