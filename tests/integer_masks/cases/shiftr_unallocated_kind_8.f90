program p
implicit none
integer(8),allocatable::a(:)
print *,kind(shiftr(a,1))
end program
