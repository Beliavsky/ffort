program main
implicit none
character(:),allocatable::a(:)
call make()
call make(a)
if(.not.allocated(a)) error stop 1
if(len(a)/=3.or.any(a/='new')) error stop 2
call make(a)
print *, 'PASS' 
contains
subroutine make(x)
character(:),allocatable,optional,intent(out)::x(:)
if(present(x)) then
if(allocated(x)) error stop 3
allocate(character(3)::x(2))
x='new'
end if
end subroutine
end program
