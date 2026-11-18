function any_strings_in_lines(lines,search_strings,case_sensitive) result(found)
! return .true. if any of search_strings(:) are found in lines(:)
character (len=*), intent(in) :: lines(:)
character (len=*), intent(in) :: search_strings(:)
logical, intent(in), optional :: case_sensitive
logical                       :: found
integer                       :: i,nstrings
nstrings = size(search_strings)
if (nstrings < 1) then
   found = .false.
   return
end if
found = .true.
do i=1,nstrings
   if (text_in_lines(lines,trim(search_strings(i)),case_sensitive)) return
end do
found = .false.
end function any_strings_in_lines
!
