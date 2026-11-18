program p
implicit none

print *,erfc_scaled(0.),erfc_scaled(-0.),erfc_scaled(0.17),erfc_scaled(-2.),kind(erfc_scaled(1.))
end program
