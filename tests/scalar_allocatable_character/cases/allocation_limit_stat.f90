program p
implicit none
character(:),allocatable::s
integer::i
allocate(character(65537)::s,stat=i)
if(i==0.or.allocated(s)) error stop 1
s='old'
allocate(character(65537)::s,stat=i)
if(i==0.or.s/='old') error stop 2
end program
