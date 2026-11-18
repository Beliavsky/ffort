program p
implicit none

real(4)::x
x=huge(1.0_4)
print *,nearest(x,1.0_4)
end program
