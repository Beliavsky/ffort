program p
implicit none

call s([1.,2.],[1.,2.,3.])
contains
subroutine s(a,b)
real,intent(in)::a(:),b(:)
print *,dprod(a,b)
end subroutine
end program
