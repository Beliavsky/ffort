program p
implicit none

real(8)::x
x=-huge(1.0_8)
print *,nearest(x,-1.0_8)
end program
