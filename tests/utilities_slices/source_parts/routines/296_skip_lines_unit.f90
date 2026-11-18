subroutine skip_lines_unit(iu,nlines)
integer, intent(in)           :: iu
integer, intent(in), optional :: nlines
integer                       :: i
if (.not. present(nlines)) return
do i=1,nlines
   read (iu,*)
end do
end subroutine 
!
