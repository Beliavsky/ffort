program p
implicit none
call f([-1.5d0,0.5d0,2.5d0])
contains
subroutine f(x)
real(8),intent(in)::x(:)
print *,aint(x),anint(x,4),asinh(x),acosh(abs(x)+1d0)
end subroutine
end program
