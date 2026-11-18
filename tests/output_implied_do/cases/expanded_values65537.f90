program main
implicit none
integer::i,a(32768)
write(*,'(a)') "before"
a=7
print *, 8,(a,i=1,2)
end program
