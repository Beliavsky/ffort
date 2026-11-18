program p
implicit none
character(:),allocatable::x,y(:)
integer::i
allocate(character(65536)::x)
x=repeat("a",65536)
y=[(x,i=1,257)]
end program
