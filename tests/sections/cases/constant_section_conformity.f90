program probe
implicit none
integer :: a(4),b(5)
a=1
b=2
a(:)=b(:)
end program probe
