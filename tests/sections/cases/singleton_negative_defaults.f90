program probe
implicit none
integer :: a(-3:-3)
a=7
print *, a(::-1)
end program probe
