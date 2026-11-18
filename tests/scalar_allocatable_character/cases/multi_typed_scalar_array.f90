program p
implicit none
character(:),allocatable::s,a(:)
allocate(character(2)::s,a(2))
s(:)='s';a='xy'
if(s/='s '.or.any(a/='xy')) error stop 1
deallocate(s,a)
end program
