program p
implicit none
character(:),allocatable::a
allocate(character(2)::a)
a='ab'
print *,lle(a,'ab ')
end program
