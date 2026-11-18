program p
implicit none
character(:),allocatable::x(:),y(:)
integer::i
allocate(character(3)::x(2))
x=["one","two"]
y=[(x,i=1,2)]
if(size(y)/=4.or.len(y)/=3)stop 1
write(*,"(*(a))")y
end program
