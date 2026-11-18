function join_csv(words) result(str)
! trim and concatenate a vector of character variables,
! inserting a comma between them
character (len=*), intent(in)                            :: words(:)
character (len=(size(words)-1)*1 + sum(len_trim(words))) :: str
integer                                                  :: i,nw
nw  = size(words)
if (nw < 1) then
   str = ""
   return
end if
write (str,"(10000(a))") trim(words(1)),("," // trim(words(i)), i = 2,nw)
end function join_csv
!
