program p
implicit none
real(4)::x
x=huge(0.0_4)
print *,sind(x),sind(-x)
end program
