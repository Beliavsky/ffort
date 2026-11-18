program p
implicit none

real(4),parameter::x=spacing(1.0_4),y=nearest(1.0_4,-1.0_4)
print *,x==epsilon(1.0_4),y<1.0_4
end program
