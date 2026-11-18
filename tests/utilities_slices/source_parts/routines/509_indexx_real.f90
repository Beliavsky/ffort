function indexx_real(xx) result(iord)
! return iord(:) such that xx(iord) is sorted
real(kind=dp), intent(in) :: xx(:)
integer                   :: iord(size(xx))
real(kind=dp)             :: xcp(size(xx))
xcp = xx
call quick_sort(xcp,iord)
end function indexx_real
!
