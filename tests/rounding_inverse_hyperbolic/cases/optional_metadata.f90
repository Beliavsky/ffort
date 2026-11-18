program p
implicit none
call f()
contains
subroutine f(x)
real(8),optional,intent(in)::x(:)
print *,kind(aint(x,4)),kind(anint(x)),kind(asinh(x)),kind(acosh(x))
end subroutine
end program
