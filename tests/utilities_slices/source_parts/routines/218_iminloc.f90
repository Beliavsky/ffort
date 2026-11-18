function iminloc(arr)
real(kind=dp), dimension(:), intent(in) :: arr
integer, dimension(1) :: imin
integer :: iminloc
imin=minloc(arr(:))
iminloc=imin(1)
end function iminloc
!
