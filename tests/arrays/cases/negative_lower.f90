program probe
implicit none
integer :: a(-3:-1)
a(-3)=30
a(-2)=20
a(-1)=10
print *,a(-3),a(-2),a(-1)
end program probe
