program p
implicit none
integer,allocatable :: a(:),b(:)
allocate(a(3))
a(2)=7
call move_alloc(a,b)
print *,b(1)
end program
