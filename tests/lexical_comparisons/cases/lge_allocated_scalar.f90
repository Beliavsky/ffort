program p
implicit none
character(:),allocatable::a
allocate(character(2)::a)
a='ab'
print *,lge(a,'ab ')
end program
