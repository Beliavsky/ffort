program p
implicit none
real(4)::x(3),a(3)
x=-3.0_4
a=-1
where([.true.,.false.,.true.])a=rrspacing(x)
print *,a
end program
