subroutine write_format(format_str,iunit,advance)
! write format_str to unit iunit if it is present and not blank
! otherwise, do nothing
character (len=*), intent(in), optional :: format_str
integer          , intent(in), optional :: iunit
character (len=*), intent(in), optional :: advance
integer                                 :: iu
if (.not. present(format_str)) return
if (present(iunit)) then
   iu = iunit
else
   iu = istdout
end if
! iu = default(istdout,iunit)
if (format_str /= "") write (iu,format_str,advance=default("yes",advance))
end subroutine write_format
!
