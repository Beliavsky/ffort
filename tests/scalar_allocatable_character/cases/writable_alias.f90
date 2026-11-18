program p
implicit none
character(:),allocatable::s
s='abc'
call change(s,s)
contains
subroutine change(x,y)
character(:),allocatable,intent(inout)::x
character(*),intent(in)::y
x=y//'z'
end subroutine
end program
