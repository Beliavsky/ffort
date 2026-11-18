module m
implicit none
contains
subroutine work(x,n)
character(*),intent(in)::x(:)
integer,optional,intent(in)::n
character(len=len(x(n)))::y
end subroutine
end module
program main
end program
