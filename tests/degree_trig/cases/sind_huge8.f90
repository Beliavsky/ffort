program p
implicit none
real(8)::x
x=huge(0.0_8)
print *,sind(x),sind(-x)
end program
