program probe
implicit none
integer :: a(3), b(3)
a(1)=-7
a(2)=8
a(3)=9
b(1)=3
b(2)=-3
b(3)=4
print *, mod(a,b),mod(a,3),mod(10,b)
end program probe
