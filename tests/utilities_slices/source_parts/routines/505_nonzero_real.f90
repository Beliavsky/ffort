function nonzero_real(xx) result(xnz)
! return the nonzero values of xx(:)
real(kind=dp), intent(in)  :: xx(:)
real(kind=dp), allocatable :: xnz(:)
call set_alloc(pack(xx,xx/=0.0_dp),xnz)
end function nonzero_real
!
