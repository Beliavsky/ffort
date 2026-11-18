program p
implicit none
character(:),allocatable::s,b,c
integer::i
b='old'
allocate(character(4)::s,b,c,stat=i)
if(i==0.or..not.allocated(s).or.allocated(c)) error stop 1
if(len(s)/=4.or.b/='old'.or.len(b)/=3) error stop 2
end program
