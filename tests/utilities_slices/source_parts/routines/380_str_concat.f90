pure function str_concat(fmt,str,xx) result(new_str)
character (len=*), intent(in) :: fmt,str
real(kind=dp), intent(in) :: xx(:)
character (len=100) :: new_str
write (new_str,fmt) trim(str),xx
end function str_concat
!
