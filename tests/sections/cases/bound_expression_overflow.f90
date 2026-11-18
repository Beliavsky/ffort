program probe
implicit none
integer :: a(3),n
a=1
n=2147483647
print *, a(:n+1)
end program probe
