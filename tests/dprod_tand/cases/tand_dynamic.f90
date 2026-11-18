program p
implicit none

call s([0d0,30d0,45d0])
contains
subroutine s(a)
real(8),intent(in)::a(:)
print *,tand(a)
end subroutine
end program
