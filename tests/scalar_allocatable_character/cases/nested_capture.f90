program p
implicit none
character(:),allocatable::s
s='a'
call change()
if(s/='ab') error stop 1
contains
subroutine change()
s=s//'b'
end subroutine
end program
