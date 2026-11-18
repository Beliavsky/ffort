program p
implicit none

call s([1.,2.,3.])
contains
subroutine s(a)
real,intent(in)::a(:)
print *,dprod(a,a)
end subroutine
end program
