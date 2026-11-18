program probe
implicit none
integer :: a(65536)
a=7
print *, a(1),a(32768),a(65536)
end program probe
