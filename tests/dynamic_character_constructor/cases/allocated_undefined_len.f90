program p
implicit none
character(:),allocatable::x
integer::i
allocate(character(8)::x)
if(len([(x,i=1,3)])/=8)stop 1
print "(a)","OK"
end program
