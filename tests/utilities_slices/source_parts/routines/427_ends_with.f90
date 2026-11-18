elemental function ends_with(text,string) result(tf)
character (len=*), intent(in) :: text,string
logical                       :: tf
integer                       :: len_text,len_string
len_text = len_trim(text)
len_string = len_trim(string)
tf = .false.
if (len_string > len_text .or. len_text < 1) return
tf = text(len_text-len_string+1:len_text) == trim(string)
end function ends_with
!
