program probe
implicit none
integer :: a(3)
a(1)=2
a(2)=3
a(3)=5
a=a+a(a(1))
print *, a
end program probe
