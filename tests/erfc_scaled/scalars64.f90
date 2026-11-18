program p
implicit none

print *,erfc_scaled(0d0),erfc_scaled(-0d0),erfc_scaled(0.17d0),erfc_scaled(-2d0),kind(erfc_scaled(1d0))
end program
