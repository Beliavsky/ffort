program p
implicit none
character(:),allocatable :: a
character(3),allocatable :: b

b='old'
call move_alloc(a,b)
end program
