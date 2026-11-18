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
integer, intent(in) :: x(-3:)
r=x(-3)+10*x(1)+lbound(x,1)+ubound(x,1)
end function inspect
end program main
