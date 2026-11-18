program p
implicit none

call show(1)
contains
subroutine show(d)
integer,optional,intent(in)::d
print *,parity([.true.],dim=d)
end subroutine
end program
