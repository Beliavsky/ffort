program probe
implicit none
integer :: a(3),b(3),n
n=1
print *, a(3:2)+b(:n)
end program probe
