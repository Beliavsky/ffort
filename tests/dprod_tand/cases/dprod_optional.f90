program p
implicit none

call s()
contains
subroutine s(x)
real,optional,intent(in)::x
print *,kind(dprod(x,2.0))
end subroutine
end program
