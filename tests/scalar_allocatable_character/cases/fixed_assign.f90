program p
implicit none
character(4),allocatable::s
if(allocated(s).or.len(s)/=4) error stop 1
s='abcdef'
if(len(s)/=4.or.s/='abcd') error stop 2
s='x'
if(s/='x   ') error stop 3
end program
