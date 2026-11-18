program main
implicit none
real(8),allocatable::a(:)
call inspect()
call inspect(a)
allocate(a(0))
call inspect(a)
contains
subroutine inspect(x)
real(8),optional,intent(in)::x(:)
print *,present(x),minexponent(x),maxexponent(x),kind(minexponent(x))
end subroutine
end program
