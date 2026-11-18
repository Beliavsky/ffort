program p
implicit none
integer(4),allocatable::a(:)
allocate(a(3))
a=[0_4,8_4,-4_4]
print *,trailz(a)
deallocate(a)
end program p
