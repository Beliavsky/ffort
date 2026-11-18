program p
implicit none
real(8)::x(3)
logical::y(3)
x=[-1d0,0d0,4d0]
y=.true.
where(x>=0d0) y=isnan(sqrt(x))
print *,y
end program
