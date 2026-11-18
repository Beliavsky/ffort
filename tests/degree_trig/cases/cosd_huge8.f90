program p
implicit none
real(8)::x
x=huge(0.0_8)
print *,cosd(x),cosd(-x)
end program
