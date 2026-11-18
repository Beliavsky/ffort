program main
implicit none
character(4)::a(2,2)
character(0)::z(2,2)
character(3)::empty(0,2)
a='abcd'
call outer(a)
call outer()
call inspect(z,0)
call inspect(empty,3)
call change(a)
if(any(a/='done')) error stop 1
print *, 'PASS' 
contains
subroutine outer(x)
character(*),optional,intent(in)::x(:,:)
call inspect(x,4)
end subroutine
subroutine inspect(x,n)
character(*),optional,intent(in)::x(:,:)
integer,intent(in)::n
if(present(x)) then
if(len(x)/=n) error stop 2
end if
end subroutine
subroutine change(x)
character(4),optional,intent(out)::x(:,:)
if(present(x)) x='done'
end subroutine
end program
