module m
implicit none
contains
pure integer(8) function f(n) result(v)
integer(8),intent(in)::n
v=n+1_8
end function
subroutine run(n)
integer(8),intent(in)::n
integer::a(f(n))
a=7
print *,size(a)
end subroutine
end module
program p
use m
implicit none
call run(3_8)
end program
