program p
implicit none
character(:),allocatable::x(:),y(:)
integer::i
allocate(character(9)::x(0))
y=[x]
if(size(y)/=0.or.len(y)/=9)stop 1
print "(a)","OK"
end program
