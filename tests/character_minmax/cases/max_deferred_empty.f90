program p
implicit none
character(:),allocatable::a(:),b(:),c(:)
allocate(character(2)::a(0))
allocate(character(4)::b(0))
c=max(a,b)
print *,size(c),len(c),len(max(a,b))
end program
