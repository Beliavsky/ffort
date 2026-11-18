program probe
implicit none
integer :: a(4),b(5),n
a=1
b=2
n=3
print *, a(:n)+b(:)
end program probe
