module utility_case
implicit none
contains
function join(words,sep) result(str)
! trim and concatenate a vector of character variables,
! inserting sep between them
character (len=*), intent(in)                                   :: words(:),sep
character (len=(size(words)-1)*len(sep) + sum(len_trim(words))) :: str
integer                                                         :: i,nw
nw  = size(words)
str = ""
if (nw < 1) then
   return
else
   str = words(1)
end if
do i=2,nw
   str = trim(str) // sep // words(i) 
end do
write (str,"(10000(a))") trim(words(1)),(sep // trim(words(i)), i = 2,nw)
end function join
end module
program main
use utility_case
implicit none
character(5)::a(3),one(1),empty(0),blanks(2)
a=["alpha"," b   ","     "]
one=["only "]
blanks=""
write(*,'(a)') "["//join(a,"::")//"]"
write(*,'(a)') "["//join(one,"::")//"]"
write(*,'(a)') "["//join(empty,"::")//"]"
write(*,'(a)') "["//join(blanks,"::")//"]"
end program
