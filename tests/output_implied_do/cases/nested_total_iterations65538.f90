program main
implicit none
integer::i,j,a(0)
write(*,'(a)') "before"
print *, ((a,j=1,32768),i=1,2)
end program
