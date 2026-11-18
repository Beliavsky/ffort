program main
implicit none
integer::i,a(2)
write(*,'(a)') "before"
a(1)=1
print *, (a(i),i=1,2)
end program
