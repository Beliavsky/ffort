program p
implicit none
real(8)::a(2,2)
a=acosd(x=reshape([0.0_8,0.5_8,1.0_8,-0.5_8],[2,2]))
print *,a
end program
