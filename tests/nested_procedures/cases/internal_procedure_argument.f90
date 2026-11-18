module m
implicit none
contains
subroutine host()
integer::x
x=1
call invoke(child)
contains
subroutine child()
x=x+1
end subroutine
end subroutine
subroutine invoke(f)
interface
subroutine f()
end subroutine
end interface
call f()
end subroutine
end module
program p
use m
call host()
end program
