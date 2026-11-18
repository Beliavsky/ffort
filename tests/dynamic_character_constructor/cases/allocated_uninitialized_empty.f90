program p
implicit none
character(:),allocatable::x,y(:)
integer::i
allocate(character(8)::x)
y=[(x,i=1,0)]
if(size(y)/=0.or.len(y)/=8)stop 1
print "(a)","OK"
end program
