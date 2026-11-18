program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
print *,inspect(a(5:1:-2)+10)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=x(1)+10*x(3)+size(x)
end function inspect
end program main
