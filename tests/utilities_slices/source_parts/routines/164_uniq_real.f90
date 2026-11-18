function uniq_real(ivec,tol) result(yy)
! return the unique values in ivec(:) up to tolerance tol
real(kind=dp), intent(in)  :: ivec(:)
real(kind=dp), intent(in), optional  :: tol
real(kind=dp), allocatable :: yy(:)
call unique_values_real(ivec,yy,tol=tol)
end function uniq_real
!
