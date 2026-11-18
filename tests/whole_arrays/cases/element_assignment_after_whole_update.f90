program probe
implicit none
integer :: a(3)
a=2
a=a+3
a(2)=a(1)*a(3)
print *, a
end program probe
