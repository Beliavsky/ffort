program p
implicit none
character(:),allocatable::x,y(:)
integer::i
x="ab"
y=[(x,i=1,2)]
if(len(y)/=2)stop 1
x="Q"
y=[(x,i=1,3)]
if(len(y)/=1.or.size(y)/=3.or.any(y/="Q"))stop 2
print "(a)","OK"
end program
