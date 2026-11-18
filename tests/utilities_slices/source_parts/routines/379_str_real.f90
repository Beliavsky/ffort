elemental function str_real(xx,fmt_real) result(ch)
real(kind=dp), intent(in) :: xx
character (len=*), intent(in), optional :: fmt_real
character (len=20) :: ch
if (present(fmt_real)) then
   write (ch,fmt_real) xx
else
   write (ch,"(f20.4)") xx
end if
ch = adjustl(ch)
end function str_real
!
