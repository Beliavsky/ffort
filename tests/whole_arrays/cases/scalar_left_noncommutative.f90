program probe
implicit none
integer :: a(3), b(3), c(3)
a(1)=1
a(2)=2
a(3)=4
b=12/a
c=10-a
print *, b,c,2**a
end program probe
