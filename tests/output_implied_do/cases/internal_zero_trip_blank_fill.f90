program main
implicit none
integer::i
character(8)::buffer
buffer="abcdefgh"
write(buffer,'(8a)') ("x",i=2,1)
write(*,'(a)') "["//buffer//"]"
end program
