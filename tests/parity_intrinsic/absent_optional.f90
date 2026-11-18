program p
implicit none

call show()
contains
subroutine show(x)
logical,optional,intent(in)::x(:)
print *,parity(x)
end subroutine
end program
