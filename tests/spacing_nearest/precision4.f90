program p
implicit none

print *, spacing(1.0_4)==epsilon(1.0_4), nearest(1.0_4,1.0_4)-1.0_4==epsilon(1.0_4), &
 1.0_4-nearest(1.0_4,-1.0_4)==epsilon(1.0_4)/2
print *, kind(spacing(1.0_4)),kind(nearest(1.0_4,1.0))
end program
