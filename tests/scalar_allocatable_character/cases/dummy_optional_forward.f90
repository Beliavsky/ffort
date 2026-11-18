program p
implicit none
character(:),allocatable::s
call outer()
call outer(s)
s='yes'
call outer(s)
contains
subroutine outer(x)
character(:),allocatable,optional,intent(inout)::x
call inner(x)
end subroutine
subroutine inner(x)
character(:),allocatable,optional,intent(inout)::x
if(present(x)) then
if(allocated(x)) then
if(x/='yes') error stop 1
else
x='made'
end if
end if
end subroutine
end program
