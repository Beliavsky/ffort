program probe
implicit none
integer :: a(3)
real :: b(3)
b=1.0e20
a(3:1:-1)=b(:)
end program probe
