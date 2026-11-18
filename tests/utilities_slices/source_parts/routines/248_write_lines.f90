subroutine write_lines(outu,lines,format_str,format_header)
integer          , intent(in), optional :: outu
character (len=*), intent(in), optional :: lines(:)
character (len=*), intent(in), optional :: format_str,format_header
integer                                 :: outu_,i
outu_ = default(istdout,outu)
call write_format(format_header,iunit=outu_)
if (.not. present(lines)) return
! if (present(format_str)) write (*,*) "in write_lines, format_str = '" // trim(format_str) // "'"
do i=1,size(lines)
   if (present(format_str)) then
      write (outu_,format_str) trim(lines(i))
   else
      write (outu_,*)          trim(lines(i))
   end if
end do
end subroutine write_lines
!
