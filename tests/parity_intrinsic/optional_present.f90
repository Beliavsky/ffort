program p
implicit none

call show([.true.,.false.])
contains
subroutine show(x)
logical,optional,intent(in)::x(:)
if(present(x))print *,parity(x)
end subroutine
end program
