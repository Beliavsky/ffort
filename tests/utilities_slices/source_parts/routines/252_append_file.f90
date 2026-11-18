subroutine append_file(xfile,text)
character (len=*), intent(in)           :: xfile
character (len=*), intent(in), optional :: text(:)
integer                                 :: i,outu
if (.not. present(text)) return
inquire (file=xfile,number=outu)
do i=1,size(text)
   write (outu,"(a)") trim(text(i))
end do
end subroutine append_file
!
