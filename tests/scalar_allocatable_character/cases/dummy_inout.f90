program p
implicit none
character(:),allocatable::s
s='abc'
call grow(s)
if(s/='abcX'.or.len(s)/=4) error stop 1
contains
subroutine grow(x)
character(:),allocatable,intent(inout)::x
x=x//'X'
end subroutine
end program
