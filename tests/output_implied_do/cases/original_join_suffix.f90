module utility_case
implicit none
contains
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
end module
program main
use utility_case
implicit none
character(5)::a(3),one(1),empty(0),blanks(2)
a=["alpha"," b   ","     "]
one=["only "]
blanks=""
write(*,'(a)') "["//join_suffix(a,"!")//"]"
write(*,'(a)') "["//join_suffix(one,"!")//"]"
write(*,'(a)') "["//join_suffix(empty,"!")//"]"
write(*,'(a)') "["//join_suffix(blanks,"!")//"]"
end program
