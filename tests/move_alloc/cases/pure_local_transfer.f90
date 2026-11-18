program p
implicit none
integer :: n
n=f()
if(n/=4) error stop 1
contains
pure integer function f()
integer,allocatable :: a(:),b(:)
allocate(a(4));a=7
call move_alloc(a,b)
f=size(b)
end function
end program
