program p
implicit none
real(8)::x(3)
x=[1d0,0d0,-3d0]
print *,isnan(x),count(isnan(x))
end program
