program p
implicit none
real(4)::x
x=huge(0.0_4)
print *,cosd(x),cosd(-x)
end program
