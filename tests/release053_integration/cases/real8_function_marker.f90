module m
implicit none
contains
function head(a) result(answer)
real(8),intent(in)::a(:)
real(8)::answer
answer=a(1)
end function
end module
program p
use m
implicit none
real(8)::x(3)
x=[1.25_8,2.5_8,3.75_8]
write(*,'(2f7.2)')head(x([3,1])),head(a=(x([2,1])))
end program
