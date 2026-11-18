program probe
implicit none
integer :: a(int(-2.9):int(2.9))
a(-2)=8
a(2)=9
print *,a(-2),a(2)
end program probe
