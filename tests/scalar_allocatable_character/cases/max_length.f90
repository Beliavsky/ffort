program p
implicit none
character(:),allocatable::s
s=repeat('a',65536)
if(len(s)/=65536.or.s(65536:65536)/='a') error stop 1
s=''
if(len(s)/=0) error stop 2
end program
