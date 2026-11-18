program p
implicit none
character(:),allocatable::x,y(:)
integer::i
y=[(x,i=1,2)]
end program
