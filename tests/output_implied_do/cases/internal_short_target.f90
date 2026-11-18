program main
implicit none
integer::i
character(3)::s
write(*,'(a)') "before"
s="old"
write(s,'(4a)') ("xx",i=1,2)
end program
