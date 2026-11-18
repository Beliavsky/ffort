program probe
implicit none
integer :: a(2147483646:2147483647)
a(2147483646)=8
a(2147483647)=9
print *,a(2147483646),a(2147483647)
end program probe
