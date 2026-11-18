module utility_case
implicit none
contains
function join_csv_suffix(words,suffix) result(str)
! trim and concatenate a vector of character variables,
! inserting a comma between them
character (len=*), intent(in)                            :: words(:)
character (len=*), intent(in)                            :: suffix
! character (len=1000) :: str
character (len=(size(words)-1)*1 + sum(len_trim(words)) + size(words)*len(suffix)) :: str
integer                                                  :: i,nw
nw  = size(words)
if (nw < 1) then
   str = ""
   return
end if
write (str,"(10000(a))") trim(words(1)) // suffix,("," // trim(words(i)) // suffix, i = 2,nw)
end function join_csv_suffix
end module
program main
use utility_case
implicit none
character(5)::a(3),one(1),empty(0),blanks(2)
a=["alpha"," b   ","     "]
one=["only "]
blanks=""
write(*,'(a)') "["//join_csv_suffix(a,"!")//"]"
write(*,'(a)') "["//join_csv_suffix(one,"!")//"]"
write(*,'(a)') "["//join_csv_suffix(empty,"!")//"]"
write(*,'(a)') "["//join_csv_suffix(blanks,"!")//"]"
end program
