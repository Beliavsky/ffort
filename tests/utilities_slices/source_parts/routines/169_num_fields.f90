elemental function num_fields(text,delim,xstrip) result(n)
! find the number of fields when splitting text using delimiter delim
! if xstrip is .true. and presen, strip a delimiter appearing at the end
character (len=*), intent(in) :: text
character (len=1), intent(in), optional :: delim
logical          , intent(in), optional :: xstrip
character (len=1)                       :: delim_
logical                                 :: xstrip_
integer                                 :: n
xstrip_ = default(.true.,xstrip)
delim_ = default(",",delim)
if (xstrip_) then
   n = 1 + num_matching_char(strip(text,delim_),delim_)
else
   n = 1 + num_matching_char(text,delim_)
end if
end function num_fields
!
