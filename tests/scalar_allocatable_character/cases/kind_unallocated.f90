program p
implicit none
character(:),allocatable::s
if(kind(s)/=kind('a')) error stop 1
if(allocated(s)) error stop 2
end program
