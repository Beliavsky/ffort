program probe
implicit none
integer :: a(3)
a=1
print *, a(3:(-2147483647-1):(-2147483647-1))
end program probe
