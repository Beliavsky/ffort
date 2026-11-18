module utility_quote
implicit none
contains
function quote(text) result(quoted_text)
! return a quoted and trimmed string
character (len=*), intent(in)      :: text
character (len=len_trim(text) + 2) :: quoted_text
quoted_text = "'" // trim(text) // "'"
end function quote
end module
program p
use utility_quote
print "(a)",quote("dog   "),quote(""),quote("   "),quote(" cat ")
end program
