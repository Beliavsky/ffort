program p
implicit none
real(8)::a(4)
a=[0.0_8,0.5_8,1.0_8,-0.5_8]
print *,cosd(a(4:1:-2))
end program
