subroutine print_vector(xx,fmt_r,title,fmt_trailer,outu)
! print xx(:) to unit outu using format fmt_r
real(kind=dp)    , intent(in)           :: xx(:)
character (len=*), intent(in), optional :: fmt_r,title
character (len=*), intent(in), optional :: fmt_trailer
integer          , intent(in), optional :: outu
character (len=100)                     :: fmt_r_
integer                                 :: outu_
outu_ = default(istdout,outu)
call set_optional(fmt_r_,"(100f10.4)",fmt_r)
if (present(title)) write (outu_,*) title
if (size(xx) == 0) return
write (outu_,fmt_r_) xx
call write_format(fmt_trailer,outu_)
end subroutine print_vector
!
