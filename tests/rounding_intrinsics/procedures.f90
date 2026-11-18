module m
implicit none
contains
pure function wide(x) result(y)
real(8),intent(in)::x(:)
integer(8)::y(size(x))
y=nint(kind=8,a=x)
end function
pure function consume(x) result(y)
integer(8),intent(in)::x(:)
integer(8)::y
y=sum(x)
end function
end module
program p
use m
implicit none
real(8)::x(3)=[1.5d0,2.5d0,-0.5d0]
print *,wide(x),consume(floor(a=x,kind=8)),consume(ceiling(kind=8,a=x))
print *,consume(nint(x,8)),kind(log10(consume([1_8,2_8])*1.0d0))
end program
