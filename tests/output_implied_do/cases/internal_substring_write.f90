program main
implicit none
integer::i
character(12)::buffer
buffer="abcdefghijkl"
write(buffer(3:8),'(3(i0,a))') (i,":",i=1,3)
write(*,'(a)') "["//buffer//"]"
end program
