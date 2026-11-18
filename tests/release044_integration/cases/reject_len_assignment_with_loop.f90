program p
implicit none
integer::i
character(3)::s
s%len=2
write(*,'(*(i0))')(s%len,i=1,2)
end program
