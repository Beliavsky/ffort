program p
implicit none
integer(4)::a(2,3)
a=reshape([0_4,1_4,2_4,4_4,8_4,-8_4],[2,3])
print *,trailz(a)
print *,shape(trailz(a)),size(trailz(a)),kind(trailz(a))
end program p
