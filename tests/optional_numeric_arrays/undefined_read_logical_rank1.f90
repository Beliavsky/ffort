program main
implicit none
logical::a(-2:2)
call inspect(a)
contains
subroutine inspect(x)
logical,optional,intent(in)::x(:)
print *, x
end subroutine
end program
