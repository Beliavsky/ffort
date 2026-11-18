elemental subroutine set_optional_logical(xx,xdef,xopt)
! set xx to (xopt,xdef) if xopt (is,is not) PRESENT
logical, intent(out)          :: xx
logical, intent(in)           :: xdef
logical, intent(in), optional :: xopt
if (present(xopt)) then
   xx = xopt
else
   xx = xdef
end if
end subroutine set_optional_logical
subroutine read_comments(iu,marker,echo,comments)
! read comments from a file, treating lines beginning with marker and followed by a space or newline to be comments
integer          , intent(in) :: iu
character (len=*), intent(in) :: marker
character (len=*), intent(out), allocatable, optional :: comments(:)
logical, intent(in), optional  :: echo
integer, parameter             :: max_comments = 100
character (len=1000)           :: lines(max_comments),word,file_name
integer                        :: i,ierr,nread
logical                        :: echo_
call set_optional(echo_,.false.,echo)
nread = max_comments
inquire (unit=iu,name=file_name)
if (echo_) write (*,*) "comments from file " // trim(file_name)
do i=1,max_comments
   read (iu,"(a)",iostat=ierr) lines(i)
   if (ierr /= 0) then
      nread = i-1
      exit
   end if
   read (lines(i),*) word
   if (word /= marker) then
      backspace (iu)
      nread = i-1
      exit
   end if
   if (echo_) write (*,*) trim(lines(i))
end do
if (present(comments)) then
   allocate (comments(nread))
   comments = lines(1:nread)
end if
if (echo_) write (*,*)
end subroutine read_comments
