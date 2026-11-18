program p
implicit none
real(8)::x
x=0d0
print *,isnan(1d0/x)
end program
