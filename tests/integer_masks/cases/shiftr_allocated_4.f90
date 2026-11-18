program p
implicit none
integer(4),allocatable::a(:)
allocate(a(2))
a=[-1_4,1_4]
print *,shiftr(a,1)
deallocate(a)
end program
