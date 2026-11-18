program main

implicit none
integer :: a(5)
a(3)=6
print *,inspect(a)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=x(3)
end function inspect
end program main
