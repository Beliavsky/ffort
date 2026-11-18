program p
implicit none
real(8)::a(1,1,2),z(1,1,2)
z=0.5_8
a=acosd(z)
print *,a
end program
