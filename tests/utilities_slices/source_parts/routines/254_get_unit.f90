subroutine get_unit(iunit,xfile)
! GET_UNIT returns a free Fortran unit number if
! file xfile is not present or is not connected, returns
! unit of xfile if it is present and connected
integer, intent(out) :: iunit
character (len=*), intent(in), optional :: xfile
integer              :: i,ios
logical              :: lopen
integer, parameter   :: iu_min = 20, iu_max = 99
if (present(xfile)) then
   inquire (file=xfile,number=iunit)
   if (iunit /= bad_unit) return
end if
iunit = 0
do i = iu_min,iu_max
    inquire (unit=i,opened=lopen,iostat=ios)
    if (ios == 0) then
      if (.not. lopen) then
        iunit = i
        return
      end if
    end if
end do
end subroutine get_unit
!
