subroutine print_comment_lines(infile,comment_char,outu,fmt_header)
! print lines from infile that begin with one of the characters in comment_char
character (len=*), intent(in)           :: infile,comment_char
character (len=*), intent(in), optional :: fmt_header
integer          , intent(in), optional :: outu
integer                                 :: i,ierr_read,iu,outu_,max_read_
character (len=10000)                   :: text
max_read_ = 1000000
outu_ = default(istdout,outu)
call write_format(fmt_header,outu_)
call get_unit_open_file(infile,iu,"r")
do i=1,max_read_
   read (iu,"(a)",iostat=ierr_read) text
   if (ierr_read /= 0) exit
   if (index(comment_char,text(1:1)) /= 0) write (outu_,"(a)") trim(text)
end do
close(iu)
end subroutine print_comment_lines
!
