program main
implicit none
character(1)::a(0)
call work(a)
contains
subroutine work(x)
character(4),optional,intent(in)::x(:)
end subroutine
end program
