program main
implicit none
integer::i
write(*,'(a)') "before"
print '(2i0,a)', (i,i=1,3)
end program
