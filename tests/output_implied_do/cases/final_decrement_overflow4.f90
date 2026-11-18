program main
implicit none
integer::i,n
write(*,'(a)') "before"
n=-huge(1)-1
print *, (i,i=n,n,-1)
end program
