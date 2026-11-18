program main
implicit none
integer::i,n
character(20)::s
write(*,'(a)') "before"
s="original"
write(s,'(4i0)') (i,i=1,3),n
end program
