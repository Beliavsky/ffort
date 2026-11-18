function index_case(string,substring,case_sensitive) result(ipos)
! do case-sensitive or insensitive index
character (len=*), intent(in) :: string,substring
logical, intent(in), optional :: case_sensitive
integer                       :: ipos
logical                       :: case_sensitive_
case_sensitive_ = .false.
if (present(case_sensitive)) case_sensitive_ = case_sensitive
if (case_sensitive) then
   ipos = index(string,substring)
else
   ipos = index(lower_case_str(string),lower_case_str(substring))
end if    
end function index_case
!
