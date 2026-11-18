program p
implicit none
character(:),allocatable::a(:),b(:),c(:)
allocate(character(2)::a(0))
allocate(character(4)::b(0))
c=min(a,b)
print *,size(c),len(c),len(min(a,b))
end program
