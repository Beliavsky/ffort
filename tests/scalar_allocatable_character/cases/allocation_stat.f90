program p
implicit none
character(:),allocatable::s
integer::i
s='old'
allocate(character(9)::s,stat=i)
if(i==0.or.s/='old'.or.len(s)/=3) error stop 1
deallocate(s,stat=i)
if(i/=0.or.allocated(s)) error stop 2
deallocate(s,stat=i)
if(i==0.or.allocated(s)) error stop 3
end program
