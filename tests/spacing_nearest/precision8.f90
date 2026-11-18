program p
implicit none

print *, spacing(1.0_8)==epsilon(1.0_8), nearest(1.0_8,1.0_8)-1.0_8==epsilon(1.0_8), &
 1.0_8-nearest(1.0_8,-1.0_8)==epsilon(1.0_8)/2
print *, kind(spacing(1.0_8)),kind(nearest(1.0_8,1.0))
end program
