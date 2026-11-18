program p
implicit none
integer(8)::a(2,3)
a=reshape([0_8,1_8,2_8,4_8,8_8,-8_8],[2,3])
print *,trailz(a)
print *,shape(trailz(a)),size(trailz(a)),kind(trailz(a))
end program p
