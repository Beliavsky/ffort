program p
implicit none
character(:),allocatable::x(:)
integer::i
x=["ab","cd"]
x=[(x,i=1,2)]
if(size(x)/=4.or.len(x)/=2)stop 1
write(*,"(*(a))")x
end program
