program p
implicit none
integer(8)::a,b
real(8)::x
print *,kind(dim(a,b)),kind(sign(a,b)),kind(log_gamma(x))
end program
