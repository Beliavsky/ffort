program p
implicit none
real(8)::x(3),y(3)
x=[-huge(0d0),0d0,2d0]
y=7d0
where(x>=0d0) y=erfc_scaled(x)
print *,y
end program
