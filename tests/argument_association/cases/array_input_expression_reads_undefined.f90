program main

implicit none
integer :: a(3)
a(1)=1
print *,inspect(a+1)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=x(1)
end function inspect
end program main
