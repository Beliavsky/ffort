program p
implicit none
real(4)::a(4)
a=[0.0_4,0.5_4,1.0_4,-0.5_4]
print *,acosd(a(4:1:-2))
end program
