program p
implicit none
real(4)::a(1,1,2),z(1,1,2)
z=0.5_4
a=acosd(z)
print *,a
end program
