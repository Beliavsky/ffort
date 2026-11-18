function element_char(i,xvec,xdef) result(xx)
! return xdef or xvec(i)
integer          , intent(in), optional :: i
character (len=*), intent(in), optional :: xvec(:)
character (len=*), intent(in), optional :: xdef
character (len=1000)                    :: xx
if (present(xdef)) then
   xx = xdef
else
   xx = ""
end if
if (present(xvec)) then
   if (present(i)) then
      if (i > 0 .and. i <= size(xvec)) xx = xvec(i)
   end if
end if
end function element_char
!
