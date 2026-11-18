program p
implicit none
character(:),allocatable::a
allocate(character(2)::a)
a='ab'
print *,lgt(a,'ab ')
end program
