program integration_main
implicit none
real::a(3)
a=0
print *,cshift(array=erfc_scaled(a),shift=1,shift=2)
end program
