program p
implicit none
character(:),allocatable::s
call outer(s)
s='yes'
call outer(s)
contains
subroutine outer(x)
character(*),optional,intent(in)::x
call inner(x)
end subroutine
subroutine inner(x)
character(*),optional,intent(in)::x
if(present(x)) then
if(x/='yes') error stop 1
end if
end subroutine
end program
