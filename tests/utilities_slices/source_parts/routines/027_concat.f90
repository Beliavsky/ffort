function concat(cvec,sep,cquote) result(yy)
! join strings
character (len=*), intent(in) :: cvec(:)
character (len=*), intent(in), optional :: sep,cquote
character (len=100*size(cvec)) :: yy
if (present(sep) .and. present(cquote)) then
   yy = join_(cvec,sep,cquote)
else if (present(cquote)) then
   yy = join_(cvec," ",cquote)
else if (present(sep)) then
   yy = join_(cvec,sep,"")
else
   yy = join_(cvec," ","")
end if
end function concat
!
