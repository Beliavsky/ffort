program main
implicit none
integer(4),allocatable::a(:,:)
call forward(a)
call forward()
call make(a)
if(.not.allocated(a)) error stop 10
if(any(a/=2)) error stop 11
call change(a)
if(any(a/=7)) error stop 12
call make(a)
if(any(a/=2)) error stop 13
call make()
print *, 'PASS'
contains
subroutine forward(x)
integer(4),allocatable,optional,intent(in)::x(:,:)
if(present(x)) then
if(allocated(x)) error stop 1
end if
call ordinary(x=x)
call allocation(expected=present(x),x=x)
end subroutine
subroutine ordinary(x)
integer(4),optional,intent(in)::x(:,:)
if(present(x)) error stop 2
end subroutine
subroutine allocation(x,expected)
integer(4),allocatable,optional,intent(in)::x(:,:)
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 3
end subroutine
subroutine make(x)
integer(4),allocatable,optional,intent(out)::x(:,:)
if(present(x)) then
if(allocated(x)) error stop 4
allocate(x(-2:2,4:5))
x=2
end if
end subroutine
subroutine change(x)
integer(4),allocatable,optional,intent(inout)::x(:,:)
if(present(x)) then
if(lbound(x,1)/=-2) error stop 5
if(any(x/=2)) error stop 6
x=7
end if
end subroutine
end program
