subroutine skip_lines(nlines,iu,xaction)
integer          , intent(in) :: nlines
integer          , intent(in) :: iu
character (len=*), intent(in) :: xaction
integer :: i
if (xaction == "r") then
   do i=1,nlines
      read (iu,*)
   end do
end if
end subroutine skip_lines
!
