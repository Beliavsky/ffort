program p
implicit none
character(7),allocatable::x
integer::i
write(*,"(i0,1x,i0)")len([(x,i=1,0)]),size([(x,i=1,0)])
end program
