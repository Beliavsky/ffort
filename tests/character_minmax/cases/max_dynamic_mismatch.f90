program p
implicit none
character(:),allocatable::a(:),b(:)
allocate(character(2)::a(2),b(3))
a='a'
b='b'
print *,'must not leak',max(a,b)
end program
