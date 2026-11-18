program main
implicit none
integer::a(2)=[1,2]
real(8)::x(3)
print *,a+minexponent(x),a+maxexponent(x)
end program
