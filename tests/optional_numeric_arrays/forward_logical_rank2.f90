program main
implicit none
logical::a(-2:2,4:5),empty(0,2)
a=.true.
call outer(a)
call outer()
call inspect(x=a(2:-2:-2,4:5),n=6,expected=.true.)
call inspect(x=empty,n=0,expected=.true.)
call change(a(2:-2:-2,4:5))
if(any(a(2:-2:-2,4:5).neqv..false.)) error stop 10
call output(a)
if(any(a.neqv..false.)) error stop 11
print *, 'PASS'
contains
subroutine outer(x)
logical,optional,intent(in)::x(:,:)
call inspect(expected=present(x),n=10,x=x)
end subroutine
subroutine inspect(x,n,expected)
logical,optional,intent(in)::x(-3:,5:)
integer,intent(in)::n
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 1
if(present(x)) then
if(size(x)/=n) error stop 2
if(n>0) then
if(lbound(x,1)/=-3) error stop 3
if(any(x.neqv..true.)) error stop 4
end if
end if
end subroutine
subroutine change(x)
logical,optional,intent(inout)::x(:,:)
if(present(x)) x=.false.
end subroutine
subroutine output(x)
logical,optional,intent(out)::x(:,:)
if(present(x)) x=.false.
end subroutine
end program
