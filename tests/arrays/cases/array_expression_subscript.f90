program probe
implicit none
integer :: a(5),i
i=2
a(i*2-1)=8
a(1)=3
print *,a(a(1)),a(i+1)
end program probe
