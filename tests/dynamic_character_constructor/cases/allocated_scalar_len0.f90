program p
implicit none
character(:),allocatable::x,y(:)
integer::i
allocate(character(0)::x)
x=repeat("a",0)
y=[(x,i=1,3)]
if(len(y)/=0.or.size(y)/=3.or.any(y/=x))stop 1
print "(a)","OK"
end program
