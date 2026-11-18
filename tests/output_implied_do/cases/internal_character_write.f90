program main
implicit none
integer::i
character(24)::buffer
buffer="old"
write(buffer,'(3(i0,a))') (i,":",i=1,3)
write(*,'(a)') "["//buffer//"]"
print *,i
end program
