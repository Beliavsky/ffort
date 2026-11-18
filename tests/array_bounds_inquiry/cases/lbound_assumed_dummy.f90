program main
real::a(-2:0,-3:-2)
call s(a)
contains
subroutine s(x)
real,intent(in)::x(0:,5:)
if(any(lbound(x)/=[0,5])) error stop 1
end subroutine
end program
