function quote(text) result(quoted_text)
! return a quoted and trimmed string
character (len=*), intent(in)      :: text
character (len=len_trim(text) + 2) :: quoted_text
quoted_text = "'" // trim(text) // "'"
end function quote
!
