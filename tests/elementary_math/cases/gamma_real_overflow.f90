program p
implicit none
real(8)::x
x=1d308
print *,log_gamma(x)
end program
