program main
implicit none
integer::i
i=2
print *, (i,i=i,3*i,i)
print *,i
end program
