program probe
implicit none
integer, parameter :: n=4, value=3**2
integer :: a(-2:n-3)
a=value
print *, a
end program probe
