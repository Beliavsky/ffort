program main
implicit none
integer::i
integer(8)::n
write(*,'(a)') "before"
n=2147483648_8
print *, (i,i=1,2,n)
end program
