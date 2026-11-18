program p
implicit none
integer(8),allocatable::a(:)
allocate(a(2))
a=[-1_8,1_8]
print *,shiftr(a,1)
deallocate(a)
end program
