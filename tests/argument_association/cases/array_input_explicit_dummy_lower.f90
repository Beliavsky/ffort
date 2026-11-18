program main

implicit none
integer :: a(-2:2)
a(-2)=1
a(-1)=2
a(0)=3
a(1)=4
a(2)=5
print *,inspect(a)
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(0:)
r=x(0)+10*x(4)+size(x,1)+lbound(x,1)+ubound(x,1)
end function inspect
end program main
