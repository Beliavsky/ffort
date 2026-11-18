program p
implicit none

call s([0d0,0.5d0,1d0])
contains
subroutine s(a)
real(8),intent(in)::a(:)
print *,acos(a)
end subroutine
end program
