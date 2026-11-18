program p
implicit none
integer,parameter::dp=kind(1.0d0)

print *,repeat_real(3,2.5_8),size(repeat_real(0,1.0_8))
contains
pure function repeat_real(n,x) result(xvec)
! return 1-D array of real variables with x repeated n times
integer, intent(in)       :: n
real(kind=dp), intent(in) :: x
real(kind=dp)             :: xvec(n)
integer                   :: j
forall (j=1:n) xvec(j) = x
end function repeat_real
end program
