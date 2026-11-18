program p
implicit none
character(:),allocatable::s
s=make()//make()
if(s/='donedone') error stop 1
contains
function make() result(x)
character(:),allocatable::x
if(allocated(x)) error stop 2
x='done'
end function
end program
