program probe
implicit none
integer :: a(-2147483647-1:-2147483647), b(2147483646:2147483647)
a=5
b=a+2
print *, a,b,b(2147483647)
end program probe
