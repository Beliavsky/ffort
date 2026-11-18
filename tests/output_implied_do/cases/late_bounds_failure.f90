program main
implicit none
integer::i,a(2)
write(*,'(a)') "before"
a=[1,2]
print *, (a(i),i=1,3)
end program
