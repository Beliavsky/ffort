module m
implicit none
contains
subroutine work(x)
character(*),optional,intent(in)::x(:)
character(len=len(x(1)))::y
end subroutine
end module
program main
end program
