module utility_case
implicit none
contains
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
end module
program main
use utility_case
implicit none
character(5)::a(3),one(1),empty(0),blanks(2)
a=["alpha"," b   ","     "]
one=["only "]
blanks=""
write(*,'(a)') "["//join_csv(a)//"]"
write(*,'(a)') "["//join_csv(one)//"]"
write(*,'(a)') "["//join_csv(empty)//"]"
write(*,'(a)') "["//join_csv(blanks)//"]"
end program
