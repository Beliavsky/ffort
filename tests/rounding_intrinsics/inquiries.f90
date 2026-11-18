program p
implicit none
real(8)::x,z(0)
print *,kind(nint(x)),kind(floor(x,kind=8)),kind(ceiling(x)),kind(log10(x))
print *,kind(nint(z,kind=kind(x))),kind(log10(z))
end program
