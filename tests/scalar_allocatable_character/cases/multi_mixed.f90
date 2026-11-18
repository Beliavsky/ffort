program p
implicit none
character(3),allocatable::s
integer,allocatable::a(:)
integer::i
allocate(s,a(2),stat=i)
if(i/=0.or..not.allocated(s).or..not.allocated(a)) error stop 1
s='abc';a=7
if(s/='abc'.or.any(a/=7)) error stop 2
deallocate(a,s,stat=i)
if(i/=0.or.allocated(s).or.allocated(a)) error stop 3
end program
