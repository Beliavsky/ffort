program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
print *,inspect(a+2*a)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=x(1)+x(5)
end function inspect
end program main
