program p
implicit none
character(3) :: x(1)
call fill(3,x)
contains
subroutine fill(n,a)
integer,intent(in) :: n
character(len=n),intent(out) :: a(:)
a='abc'
end subroutine
end program
