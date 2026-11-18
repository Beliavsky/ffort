module m
implicit none
contains
subroutine f(x)
character(*),intent(out)::x
return
end subroutine
end module
program p
use m
implicit none
character(3)::x
x='ABC'
call f(x)
print *,x
end program
