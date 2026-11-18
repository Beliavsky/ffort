program probe
implicit none
integer :: a(-2:2)
a(mod(5,3))=19
a(-abs(2))=7
print *,a(min(-2,-1)),a(int(2.8))
end program probe
