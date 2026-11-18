program p
implicit none
real(8)::x(3),y(3)
x=[1d0,0d0,2d0]
y=0d0
where(x>0d0) y=bessel_y0(x)
print *,y
end program
