module m
implicit none
interface operator(.flip.)
module procedure neg
end interface
contains
pure integer function neg(x) result(y)
integer,intent(in)::x
y=-x
end function
end module
program p
use m
implicit none
integer::i
i=.flip. 3
if(i/=-3) error stop 1
if('.flip.'/='.flip.') error stop 2
print *, 'defined unary'
end program
