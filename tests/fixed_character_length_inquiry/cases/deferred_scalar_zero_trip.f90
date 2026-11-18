program p
character(:),allocatable::x
integer::i
write(*,"(i0)")len([(x,i=1,0)])
end program
