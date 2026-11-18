program integration_main
implicit none
real::a(2,2,2),b(2,2,2)
a=0
b=cshift(erfc_scaled(a),1)
end program
