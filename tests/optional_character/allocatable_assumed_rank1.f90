program main
implicit none
character(4),allocatable::a(:)
call inspect(a,.true.)
call inspect(expected=.false.)
call ordinary(a,.false.)
allocate(a(2))
a='abcd'
call inspect(a,.true.)
call ordinary(a,.true.)
call change(a)
if(any(a/='done')) error stop 1
print *, 'PASS' 
contains
subroutine inspect(x,expected)
character(*),allocatable,optional,intent(in)::x(:)
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 9
if(present(x)) then
if(allocated(x)) then
if(len(x)/=4.or.any(x/='abcd')) error stop 2
end if
end if
call forward(x,expected)
end subroutine
subroutine forward(x,expected)
character(*),allocatable,optional,intent(in)::x(:)
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 10
end subroutine
subroutine ordinary(x,expected)
character(*),optional,intent(in)::x(:)
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 9
if(present(x)) then
if(len(x)/=4) error stop 3
end if
end subroutine
subroutine change(x)
character(*),allocatable,optional,intent(inout)::x(:)
if(present(x)) x='done'
end subroutine
end program
