program main
implicit none
character(12)::s
s=render(3)
write(*,'(a)') "["//s//"]"
contains
function render(n) result(s)
integer,intent(in)::n
integer::i
character(12)::s
write(s,'(6(i0,a))') (i,":",i=1,n)
end function
end program
