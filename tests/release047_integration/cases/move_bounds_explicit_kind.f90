program p
implicit none
integer(8),allocatable::a(:),b(:)
integer::u
u=27
allocate(a(-2:0))
read(u,*)a
call move_alloc(to=b,from=a)
print '(5i22)',lbound(b,kind=8),ubound(b,kind=8),b
end program
