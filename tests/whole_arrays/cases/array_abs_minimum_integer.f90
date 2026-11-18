program probe
implicit none
integer :: a(2)
a(1)=2
a(2)=-2147483647-1
print *,99
a=abs(a)
end program probe
