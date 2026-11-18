program p
implicit none
real(4)::x(5),a(5)
x=-3.0_4
a=-1
a(5:1:-2)=rrspacing(x(1:5:2))
print *,a
end program
