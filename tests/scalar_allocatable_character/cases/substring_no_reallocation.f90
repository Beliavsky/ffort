program p
implicit none
character(:),allocatable::s
s='abcd'
s(:)='q'
if(len(s)/=4.or.s/='q   ') error stop 1
s(2:3)='xy'
if(s/='qxy ') error stop 2
end program
