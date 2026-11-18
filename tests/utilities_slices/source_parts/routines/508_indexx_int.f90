function indexx_int(xx) result(iord)
! return iord(:) such that xx(iord) is in ascending order
integer, intent(in) :: xx(:)
integer             :: iord(size(xx))
iord = indexx_real(1.0_dp*xx)
end function indexx_int
!
