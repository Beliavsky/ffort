program main

implicit none
integer :: a(3)
a(1)=1
print *,inspect(a)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=x(2)
end function inspect
end program main
