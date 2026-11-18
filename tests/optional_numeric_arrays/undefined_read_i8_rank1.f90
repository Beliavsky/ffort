program main
implicit none
integer(8)::a(-2:2)
call inspect(a)
contains
subroutine inspect(x)
integer(8),optional,intent(in)::x(:)
print *, x
end subroutine
end program
