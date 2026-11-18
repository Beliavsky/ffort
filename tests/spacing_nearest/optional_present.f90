program p
implicit none

call sub(1d0)
contains
subroutine sub(x)
real(8),optional,intent(in)::x
print *,present(x),spacing(x)==epsilon(x),nearest(x,1.)>x
end subroutine
end program
