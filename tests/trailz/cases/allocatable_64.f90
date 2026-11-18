program p
implicit none
integer(8),allocatable::a(:)
allocate(a(3))
a=[0_8,8_8,-4_8]
print *,trailz(a)
deallocate(a)
end program p
