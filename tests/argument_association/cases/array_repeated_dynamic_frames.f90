program main

implicit none
integer :: a(5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
print *,inspect(a(1:1)),inspect(a),inspect(a(3:4))
contains
integer function inspect(x) result(r)
integer, intent(in) :: x(:)
r=size(x)*100+x(1)+x(size(x))
end function inspect
end program main
