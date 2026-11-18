program p
implicit none

print *,isnan(0.0),isnan(-0.0),isnan(0d0),isnan(-1d20),kind(isnan(1d0))
end program
