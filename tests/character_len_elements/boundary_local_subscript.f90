module m
implicit none
contains
subroutine work(x)
character(*),intent(in)::x(:)
integer::n
character(len=len(x(n)))::y
end subroutine
end module
program main
end program
