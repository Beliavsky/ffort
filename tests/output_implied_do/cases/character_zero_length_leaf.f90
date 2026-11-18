program main
implicit none
integer::i
character(0)::a(2)
a=""
write(*,'(a,4a,a)') "<",(a,i=1,2),">"
end program
