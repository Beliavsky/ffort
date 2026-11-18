program p
implicit none

call s()
contains
subroutine s(x)
real,optional,intent(in)::x
print *,spacing(x)
end subroutine
end program
