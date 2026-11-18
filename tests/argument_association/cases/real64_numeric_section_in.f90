program main

implicit none
real(8) :: a(5)
a=1.25_8
print *,inspect(a(5:1:-2))
contains
real(8) function inspect(x) result(r)
real(8), intent(in) :: x(:)
r=x(1)+x(3)
end function inspect
end program main
