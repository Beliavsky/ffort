program p
implicit none

call s()
contains
subroutine s(x)
real(8),optional,intent(in)::x
print *,kind(acos(x))
end subroutine
end program
