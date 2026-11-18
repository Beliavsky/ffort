program main
implicit none
real(4)::a(-2:2),empty(0)
a=2.0
call outer(a)
call outer()
call inspect(x=a(2:-2:-2),n=3,expected=.true.)
call inspect(x=empty,n=0,expected=.true.)
call change(a(2:-2:-2))
if(any(a(2:-2:-2)/=7.0)) error stop 10
call output(a)
if(any(a/=7.0)) error stop 11
print *, 'PASS'
contains
subroutine outer(x)
real(4),optional,intent(in)::x(:)
call inspect(expected=present(x),n=5,x=x)
end subroutine
subroutine inspect(x,n,expected)
real(4),optional,intent(in)::x(-3:)
integer,intent(in)::n
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 1
if(present(x)) then
if(size(x)/=n) error stop 2
if(n>0) then
if(lbound(x,1)/=-3) error stop 3
if(any(x/=2.0)) error stop 4
end if
end if
end subroutine
subroutine change(x)
real(4),optional,intent(inout)::x(:)
if(present(x)) x=7.0
end subroutine
subroutine output(x)
real(4),optional,intent(out)::x(:)
if(present(x)) x=7.0
end subroutine
end program
