program p
implicit none
real(8)::x(2,1,2),a(2,1,2)
x=-3.0_8
a=rrspacing(x)
print *,a,shape(a)
end program
