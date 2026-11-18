subroutine write_int(label,ivec,frmt)
character (len=*), intent(in) :: label
integer          , intent(in) :: ivec(:)
character (len=*), intent(in), optional :: frmt
character (len=1000) :: frmt_
if (present(frmt)) then
   frmt_ = frmt
else
   frmt_ = "(a,10000(1x,i0))"
end if
write (*,frmt_) trim(label),ivec
end subroutine write_int
!
