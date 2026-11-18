program p
implicit none
character(:),allocatable::s
s=make()
if(s/='done'.or.len(s)/=4) error stop 1
contains
function make() result(x)
character(:),allocatable::x
x='done'
end function
end program
