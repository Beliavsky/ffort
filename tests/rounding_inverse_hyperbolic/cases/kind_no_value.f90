program p
implicit none
real(8)::x,bad,large
bad=-1d0
large=huge(1d0)
print *,kind(aint(x)),kind(anint(x,4)),kind(asinh(x)),kind(acosh(x))
print *,kind(acosh(bad)),kind(aint(large,4))
end program
