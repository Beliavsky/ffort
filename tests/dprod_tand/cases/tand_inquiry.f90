program p
implicit none
real(8)::x,bad=90d0,large=1d200
print *,kind(tand(x)),kind(tand(bad)),kind(tand(large))
end program
