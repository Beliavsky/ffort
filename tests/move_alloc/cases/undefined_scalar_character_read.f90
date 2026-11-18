program p
implicit none
character(:),allocatable :: a,b
allocate(character(3)::a)
call move_alloc(a,b)
print *,b
end program
