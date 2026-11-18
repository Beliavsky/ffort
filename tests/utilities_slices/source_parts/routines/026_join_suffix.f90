function join_suffix(words,suffix) result(str)
! trim and concatenate a vector of character variables,
! inserting a suffix after each trimmed element
character (len=*), intent(in)                                    :: words(:)
character (len=*), intent(in)                                    :: suffix
character (len=(size(words)*len(suffix) + sum(len_trim(words)))) :: str
integer                                                          :: i,nw
nw  = size(words)
str = ""
if (nw < 1) return
write (str,"(10000(a))") (trim(words(i)) // suffix, i = 1,nw)
end function join_suffix
!
