module m
use iso_fortran_env,only:int64
implicit none
contains
function head(a) result(answer)
integer(int64),intent(in)::a(:)
integer(int64)::answer
answer=a(1)
end function
end module
program p
use m
implicit none
integer(int64)::x(4),bits(3)
x=[10_int64,20_int64,30_int64,40_int64]
bits=[8_int64,1_int64,2_int64]
write(*,'(2i4)')head(x(trailz(bits)+1)),head(a=(x(trailz([2_int64,1_int64])+1)))
end program
