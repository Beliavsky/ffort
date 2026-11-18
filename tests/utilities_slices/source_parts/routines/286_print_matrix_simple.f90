subroutine print_matrix_simple(xx,fmt_r,title,fmt_header,fmt_trailer,outu)
! write matrix xx(:,:)
real(kind=dp)    , intent(in)           :: xx(:,:) ! data to be written
character (len=*), intent(in), optional :: fmt_r   ! format to use in writing data
character (len=*), intent(in), optional :: title   ! title
character (len=*), intent(in), optional :: fmt_header,fmt_trailer ! formats to print at beginning and end of subroutine
integer          , intent(in), optional :: outu
character (len=100)                     :: fmt_r_
integer                                 :: i,outu_
outu_ = default(istdout,outu)
call set_optional(fmt_r_,"(1000(f10.4,1x))",fmt_r)
call write_format(fmt_header,outu_)
if (present(title)) write (outu_,*) title
if (size(xx) == 0) return
do i=1,size(xx,1)
   write (outu_,fmt_r_) xx(i,:)
end do
call write_format(fmt_trailer,outu_)
end subroutine print_matrix_simple
!
