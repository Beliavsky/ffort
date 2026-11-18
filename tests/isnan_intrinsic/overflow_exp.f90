program p
implicit none
real(8)::x
x=1000d0
print *,isnan(exp(x))
end program
