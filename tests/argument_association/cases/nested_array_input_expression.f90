program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
print *,inspect(a)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=next(x(5:1:-2)+1)
end function inspect
integer function next(y) result(r)
integer, intent(in) :: y(-2:)
r=y(-2)+10*y(0)
end function next
end program main
