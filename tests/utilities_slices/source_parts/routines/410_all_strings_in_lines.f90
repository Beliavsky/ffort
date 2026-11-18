function all_strings_in_lines(lines,search_strings,case_sensitive) result(found)
! return .true. if all search_strings(:) are found in lines(:)
character (len=*), intent(in) :: lines(:)
character (len=*), intent(in) :: search_strings(:)
logical, intent(in), optional :: case_sensitive
logical                       :: found
integer                       :: i,nstrings
nstrings = size(search_strings)
found = .false.
if (nstrings < 1) return
do i=1,nstrings
   if (.not. text_in_lines(lines,trim(search_strings(i)),case_sensitive)) return
end do
found = .true.
end function all_strings_in_lines
!
!
