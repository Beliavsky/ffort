program p
implicit none
character(:),allocatable::s
s=make()
if(s/='abc') error stop 1
contains
pure function make() result(x)
character(:),allocatable::x
x='abc'
end function
end program
