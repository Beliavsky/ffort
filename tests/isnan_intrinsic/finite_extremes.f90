program p
implicit none

print *,isnan(huge(1.0)),isnan(tiny(1.0)),isnan(huge(1d0)),isnan(tiny(1d0)),isnan(tiny(1d0)/2d0)
end program
