program p
implicit none
real(8),parameter::a=erfc_scaled(0.17d0),b(2)=erfc_scaled([0d0,2d0])
print *,a,b
end program
