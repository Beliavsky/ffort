program p
implicit none

real(8),parameter::x=spacing(1.0_8),y=nearest(1.0_8,-1.0_8)
print *,x==epsilon(1.0_8),y<1.0_8
end program
