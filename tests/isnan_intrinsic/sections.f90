program p
implicit none
real(8)::x(3,2)
x=1d0
print *,isnan(x(3:1:-2,:)),isnan(x(:,2))
end program
