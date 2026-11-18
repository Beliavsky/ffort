module m
implicit none
contains
subroutine work(x)
character(*),intent(in)::x(:)
character(len=len(x(:)))::y
end subroutine
end module
program main
end program
