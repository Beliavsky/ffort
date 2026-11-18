subroutine realloc_real(n,xx,xdef)
! allocate xx to size n and set elements to xdef if present
integer      , intent(in)                  :: n
real(kind=dp), intent(in out), allocatable :: xx(:)
real(kind=dp), intent(in)    , optional    :: xdef
integer                                    :: n_
n_ = max(0,n)
if (allocated(xx)) then
   if (size(xx) == n_) return
   deallocate (xx)
end if
allocate (xx(n_))
if (present(xdef)) xx = xdef
end subroutine realloc_real
!
