program main
implicit none
integer::i
write(*,'(a,6(i0,a))') "<",(i,",",i=1,3),9,">"
end program
