program p
implicit none
real::x(2,2)
x=reshape([0.,1.,2.,3.],[2,2])
print *,erfc_scaled(x)
end program
