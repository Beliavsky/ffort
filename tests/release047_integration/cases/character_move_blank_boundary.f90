program p
implicit none
integer::u
character(3),allocatable::a(:),b(:)
character(3)::c(3)
u=27
allocate(a(3))
read(u,*)a
call move_alloc(a,b)
c=eoshift(b,1)
print '(*(a))','[',c(1),'][',c(2),'][',c(3),']'
end program
