program main
implicit none
integer(8)::i,n
write(*,'(a)') "before"
n=huge(1_8)
print *, (i,i=n,n)
end program
