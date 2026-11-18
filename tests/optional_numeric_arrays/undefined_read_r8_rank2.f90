program main
implicit none
real(8)::a(-2:2,4:5)
call inspect(a)
contains
subroutine inspect(x)
real(8),optional,intent(in)::x(:,:)
print *, x
end subroutine
end program
