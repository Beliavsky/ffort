program p
implicit none
character(:),allocatable::s
s=' ab '
s=s
if(s/=' ab ') error stop 1
s=s//s
if(len(s)/=8.or.s/=' ab  ab ') error stop 2
s=s(2:3)
if(len(s)/=2.or.s/='ab') error stop 3
s=trim(adjustl('  abc  '))
if(len(s)/=3.or.s/='abc') error stop 4
end program
