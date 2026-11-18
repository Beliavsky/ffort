program p
implicit none
real(4)::a(2,2)
a=cosd(x=reshape([0.0_4,0.5_4,1.0_4,-0.5_4],[2,2]))
print *,a
end program
